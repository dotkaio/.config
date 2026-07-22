#!/usr/bin/env python3
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import tempfile
import tomllib


HOME = Path("/Users/kaioferraz")
LIVE = HOME / ".codex"
TARGET = HOME / ".agent" / "homes" / "codex"
CANONICAL_SKILLS = HOME / ".agent" / "skills"
STAMP = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
SNAPSHOT = HOME / ".agent" / "homes" / f".codex-cutover-snapshot-{STAMP}"
OLD_TARGET_BACKUP = HOME / ".agent" / "homes" / f"codex.pre-cutover-{STAMP}"


def fail(message: str) -> None:
    raise RuntimeError(message)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def atomic_write(path: Path, data: bytes, mode: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temp_path = Path(temporary)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        if mode is not None:
            os.chmod(temp_path, mode)
        os.replace(temp_path, path)
    finally:
        if temp_path.exists():
            temp_path.unlink()


def sqlite_backup(source: Path, destination: Path) -> None:
    src = sqlite3.connect(f"file:{source}?mode=ro", uri=True)
    dst = sqlite3.connect(destination)
    try:
        src.backup(dst)
        if dst.execute("pragma integrity_check").fetchone()[0] != "ok":
            fail(f"SQLite snapshot failed integrity check: {destination}")
    finally:
        dst.close()
        src.close()


def merge_tree_missing(source: Path, destination: Path, skip_names: set[str] | None = None) -> int:
    if not source.exists():
        return 0
    skip_names = skip_names or set()
    copied = 0
    for src in sorted(source.rglob("*")):
        rel = src.relative_to(source)
        if any(part in skip_names for part in rel.parts):
            continue
        dst = destination / rel
        if src.is_symlink():
            if not dst.exists() and not dst.is_symlink():
                dst.parent.mkdir(parents=True, exist_ok=True)
                dst.symlink_to(os.readlink(src), target_is_directory=src.is_dir())
                copied += 1
        elif src.is_dir():
            dst.mkdir(parents=True, exist_ok=True)
        elif not dst.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            copied += 1
    return copied


def load_index(path: Path) -> tuple[dict[str, dict], int]:
    items: dict[str, dict] = {}
    invalid = 0
    for raw in path.read_text(errors="replace").splitlines():
        try:
            obj = json.loads(raw)
        except json.JSONDecodeError:
            invalid += 1
            continue
        session_id = obj.get("id")
        if not session_id:
            continue
        prior = items.get(session_id)
        if prior is None or str(obj.get("updated_at", "")) >= str(prior.get("updated_at", "")):
            items[session_id] = obj
    return items, invalid


def rewrite_path(value: str) -> str:
    return value.replace(str(LIVE), str(TARGET))


def main() -> None:
    if LIVE.is_symlink() or not LIVE.is_dir():
        fail(f"Expected a real live Codex directory at {LIVE}")
    if TARGET.is_symlink() or not TARGET.is_dir():
        fail(f"Expected a real pre-cutover target directory at {TARGET}")
    if not CANONICAL_SKILLS.is_dir():
        fail(f"Canonical skills directory is missing: {CANONICAL_SKILLS}")
    if SNAPSHOT.exists() or OLD_TARGET_BACKUP.exists():
        fail("Timestamped backup path already exists")

    SNAPSHOT.mkdir(parents=True)
    sqlite_backup(LIVE / "state_5.sqlite", SNAPSHOT / "live-state_5.sqlite")
    sqlite_backup(TARGET / "state_5.sqlite", SNAPSHOT / "target-state_5.sqlite")

    snapshot_files = {
        "live-session_index.jsonl": LIVE / "session_index.jsonl",
        "live-config.toml": LIVE / "config.toml",
        "live-pasted-text-attachments.json": LIVE / "attachments" / "pasted-text-attachments.json",
    }
    for name, source in snapshot_files.items():
        if source.exists():
            shutil.copy2(source, SNAPSHOT / name)
    shutil.copytree(LIVE / "skills", SNAPSHOT / "live-skills", symlinks=True)

    transcript_conflicts = [
        Path("2026/07/05/rollout-2026-07-05T10-50-14-019f3366-fa10-7360-81bd-77256fdb32bb.jsonl"),
        Path("2026/07/05/rollout-2026-07-05T10-41-34-019f335f-0aea-76d2-a495-8249a503c5a7.jsonl"),
    ]
    for rel in transcript_conflicts:
        shutil.copy2(LIVE / "sessions" / rel, SNAPSHOT / f"live-{rel.name}")

    # Preserve newer system skill instructions while making .agent/skills canonical.
    skill_updates = 0
    for src in sorted((LIVE / "skills").rglob("*")):
        if not src.is_file() or src.name == ".DS_Store":
            continue
        dst = CANONICAL_SKILLS / src.relative_to(LIVE / "skills")
        if not dst.exists() or src.stat().st_mtime > dst.stat().st_mtime:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            skill_updates += 1

    copied = {
        "sessions": merge_tree_missing(TARGET / "sessions", LIVE / "sessions", {".DS_Store"}),
        "archived_sessions": merge_tree_missing(TARGET / "archived_sessions", LIVE / "archived_sessions", {".DS_Store"}),
        "attachments": merge_tree_missing(
            TARGET / "attachments",
            LIVE / "attachments",
            {".DS_Store", "pasted-text-attachments.json"},
        ),
        "worktrees": merge_tree_missing(TARGET / "worktrees", LIVE / "worktrees", {".DS_Store"}),
        "hook-logs": merge_tree_missing(TARGET / "hook-logs", LIVE / "hook-logs", {".DS_Store"}),
        "memories_extensions": merge_tree_missing(
            TARGET / "memories_extensions", LIVE / "memories_extensions", {".DS_Store"}
        ),
    }

    for name in [
        ".codex-chronicle-assets-to-install.marker",
        "chrome-native-hosts-v2.json",
        "external_agent_session_imports.json",
    ]:
        source = TARGET / name
        destination = LIVE / name
        if source.exists() and not destination.exists():
            shutil.copy2(source, destination)
            copied[name] = 1

    # The target copies are strict extensions of the live copies; retain the full transcripts.
    for rel in transcript_conflicts:
        current = LIVE / "sessions" / rel
        older_target = TARGET / "sessions" / rel
        current_bytes = current.read_bytes()
        target_bytes = older_target.read_bytes()
        if not target_bytes.startswith(current_bytes):
            fail(f"Transcript conflict is no longer a strict extension: {rel}")
        shutil.copy2(older_target, current)

    # Merge target-only thread rows using the shared schema; live-only columns keep defaults.
    live_db = sqlite3.connect(LIVE / "state_5.sqlite", timeout=30)
    old_db = sqlite3.connect(f"file:{TARGET / 'state_5.sqlite'}?mode=ro", uri=True)
    live_db.execute("pragma busy_timeout=30000")
    try:
        live_cols = [row[1] for row in live_db.execute("pragma table_info(threads)")]
        old_cols = [row[1] for row in old_db.execute("pragma table_info(threads)")]
        common = [column for column in live_cols if column in old_cols]
        quoted = ",".join('"' + c.replace('"', '""') + '"' for c in common)
        live_ids = {row[0] for row in live_db.execute("select id from threads")}
        old_rows = old_db.execute(f"select {quoted} from threads").fetchall()
        id_index = common.index("id")
        missing_rows = [row for row in old_rows if row[id_index] not in live_ids]
        placeholders = ",".join("?" for _ in common)
        live_db.execute("begin immediate")
        live_db.executemany(
            f"insert or ignore into threads ({quoted}) values ({placeholders})",
            missing_rows,
        )
        live_db.commit()
        merged_threads = live_db.execute("select count(*) from threads").fetchone()[0]
        if live_db.execute("pragma integrity_check").fetchone()[0] != "ok":
            fail("Merged live database failed integrity check")
    except Exception:
        live_db.rollback()
        raise
    finally:
        old_db.close()
        live_db.close()

    # Append only missing index rows, avoiding replacement of any concurrent live append.
    live_index, live_invalid = load_index(LIVE / "session_index.jsonl")
    old_index, old_invalid = load_index(TARGET / "session_index.jsonl")
    if live_invalid or old_invalid:
        fail(f"Invalid index lines: live={live_invalid}, target={old_invalid}")
    missing_index = [old_index[key] for key in sorted(set(old_index) - set(live_index))]
    if missing_index:
        with (LIVE / "session_index.jsonl").open("ab") as f:
            if (LIVE / "session_index.jsonl").stat().st_size and not (LIVE / "session_index.jsonl").read_bytes().endswith(b"\n"):
                f.write(b"\n")
            for item in missing_index:
                f.write(json.dumps(item, separators=(",", ":"), ensure_ascii=False).encode() + b"\n")
            f.flush()
            os.fsync(f.fileno())

    # Union pasted-text attachment state and point it at the canonical home.
    live_manifest_path = LIVE / "attachments" / "pasted-text-attachments.json"
    old_manifest_path = TARGET / "attachments" / "pasted-text-attachments.json"
    live_manifest = json.loads(live_manifest_path.read_text())
    old_manifest = json.loads(old_manifest_path.read_text())
    attachment_paths: list[str] = []
    for path in live_manifest.get("attachmentPaths", []) + old_manifest.get("attachmentPaths", []):
        path = rewrite_path(path)
        if path not in attachment_paths:
            attachment_paths.append(path)
    pending_paths: list[str] = []
    for path in live_manifest.get("pendingRemovalPaths", []) + old_manifest.get("pendingRemovalPaths", []):
        path = rewrite_path(path)
        if path not in pending_paths:
            pending_paths.append(path)
    excerpts: dict[str, str] = {}
    for manifest in [old_manifest, live_manifest]:
        for path, excerpt in manifest.get("textExcerptsByPath", {}).items():
            excerpts[rewrite_path(path)] = excerpt
    merged_manifest = {
        "attachmentPaths": attachment_paths,
        "pendingRemovalPaths": pending_paths,
        "textExcerptsByPath": excerpts,
    }
    atomic_write(
        live_manifest_path,
        (json.dumps(merged_manifest, indent=2, ensure_ascii=False) + "\n").encode(),
        live_manifest_path.stat().st_mode & 0o777,
    )

    # Make all configuration references point at the physical canonical home.
    config_path = LIVE / "config.toml"
    config_text = config_path.read_text()
    rewritten_config = config_text.replace(str(LIVE), str(TARGET))
    tomllib.loads(rewritten_config)
    atomic_write(config_path, rewritten_config.encode(), config_path.stat().st_mode & 0o777)

    # Atomic same-volume cutover. Preserve the stale target and any race-created alias directory.
    TARGET.rename(OLD_TARGET_BACKUP)
    try:
        LIVE.rename(TARGET)
    except Exception:
        OLD_TARGET_BACKUP.rename(TARGET)
        raise
    race_backup = None
    try:
        LIVE.symlink_to(TARGET, target_is_directory=True)
    except FileExistsError:
        race_backup = HOME / ".agent" / "homes" / f"codex.alias-race-{STAMP}"
        LIVE.rename(race_backup)
        LIVE.symlink_to(TARGET, target_is_directory=True)

    # Replace the moved private skills copy with the requested canonical skills tree.
    moved_skills = TARGET / "skills"
    if moved_skills.is_symlink():
        moved_skills.unlink()
    else:
        shutil.rmtree(moved_skills)
    moved_skills.symlink_to(CANONICAL_SKILLS, target_is_directory=True)

    # Final proof through both the canonical path and the compatibility symlink.
    if not LIVE.is_symlink() or LIVE.resolve() != TARGET:
        fail("Compatibility symlink verification failed")
    if not moved_skills.is_symlink() or moved_skills.resolve() != CANONICAL_SKILLS:
        fail("Canonical skills symlink verification failed")
    if (TARGET / "plugins").is_symlink() or not (TARGET / "plugins").is_dir():
        fail("Plugins directory was not preserved as a real directory")
    parsed_config = tomllib.loads((TARGET / "config.toml").read_text())
    node_env = parsed_config["mcp_servers"]["node_repl"]["env"]
    if node_env.get("CODEX_HOME") != str(TARGET):
        fail("CODEX_HOME did not move to the canonical target")
    verify_db = sqlite3.connect(f"file:{LIVE / 'state_5.sqlite'}?mode=ro", uri=True)
    try:
        final_threads = verify_db.execute("select count(*) from threads").fetchone()[0]
        integrity = verify_db.execute("pragma integrity_check").fetchone()[0]
    finally:
        verify_db.close()
    if integrity != "ok" or final_threads != merged_threads:
        fail("Final database verification failed")
    final_index, final_invalid = load_index(LIVE / "session_index.jsonl")
    if final_invalid or not set(old_index).issubset(final_index):
        fail("Final session-index coverage verification failed")
    for rel in transcript_conflicts:
        if sha256(TARGET / "sessions" / rel) != sha256(OLD_TARGET_BACKUP / "sessions" / rel):
            fail(f"Extended transcript was not preserved: {rel}")
    missing_attachments = [path for path in attachment_paths if not Path(path).exists()]
    if missing_attachments:
        fail(f"Merged attachment paths are missing: {missing_attachments[:3]}")

    result = {
        "canonical_home": str(TARGET),
        "compatibility_symlink": f"{LIVE} -> {os.readlink(LIVE)}",
        "canonical_skills": f"{moved_skills} -> {os.readlink(moved_skills)}",
        "plugins_real_directory": True,
        "threads_before": len(live_ids),
        "threads_inserted": len(missing_rows),
        "threads_after": final_threads,
        "database_integrity": integrity,
        "session_index_unique": len(final_index),
        "session_index_added": len(missing_index),
        "attachment_manifest_entries": len(attachment_paths),
        "skill_files_updated": skill_updates,
        "files_copied": copied,
        "snapshot": str(SNAPSHOT),
        "old_target_backup": str(OLD_TARGET_BACKUP),
        "race_backup": str(race_backup) if race_backup else None,
    }
    atomic_write(SNAPSHOT / "result.json", (json.dumps(result, indent=2) + "\n").encode())
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
