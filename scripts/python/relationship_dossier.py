#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import subprocess
from collections import defaultdict
from dataclasses import dataclass, asdict
from datetime import datetime
from email import policy
from email.parser import BytesParser
from pathlib import Path
from typing import Any

ROOT = Path.home() / "Developer" / "people"
MESSAGES_DB = Path.home() / "Library" / "Messages" / "chat.db"
MAIL_ROOT = Path.home() / "Library" / "Mail"
MAIL_ENVELOPE = MAIL_ROOT / "V10" / "MailData" / "Envelope Index"
MSG_SCRIPT = Path.home() / ".agents" / "skills" / "apple-messages" / "scripts" / "messages.sh"
MAIL_SCRIPT = Path.home() / ".agents" / "skills" / "apple-mail" / "scripts" / "mail.sh"

POSITIVE = {
    "thanks", "thank you", "great", "awesome", "perfect", "love", "good", "nice",
    "amazing", "glad", "yes", "works", "worked", "cool", "appreciate", "done"
}
NEGATIVE = {
    "no", "not", "issue", "problem", "bad", "hate", "wrong", "can't", "cant",
    "error", "failed", "fuck", "shit", "annoying", "delay", "stuck", "broken"
}

@dataclass
class Interaction:
    source: str
    timestamp: str
    date: str
    time: str
    direction: str
    counterpart: str
    text: str
    sentiment: str
    score: int
    meta: dict[str, Any]


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-+", "-", value).strip("-")
    return value or "person"


def score_sentiment(text: str) -> tuple[str, int]:
    lower = text.lower()
    score = 0
    for token in POSITIVE:
        if token in lower:
            score += 1
    for token in NEGATIVE:
        if token in lower:
            score -= 1
    if score > 0:
        return "positive", score
    if score < 0:
        return "negative", score
    return "neutral", score


def parse_message_time(apple_dt: str) -> datetime:
    return datetime.strptime(apple_dt, "%Y-%m-%d %H:%M:%S")


def resolve_contacts(name: str) -> list[str]:
    candidates: list[str] = []
    try:
        result = subprocess.run(
            [str(MSG_SCRIPT), "find", name], capture_output=True, text=True, check=False
        )
        for line in result.stdout.splitlines():
            line = line.strip()
            if not line:
                continue
            if line.startswith("["):
                continue
            candidates.append(line)
    except Exception:
        pass
    return sorted(set(candidates))


def fetch_imessages(handles: list[str]) -> list[Interaction]:
    if not MESSAGES_DB.exists() or not handles:
        return []

    conn = sqlite3.connect(MESSAGES_DB)
    conn.row_factory = sqlite3.Row
    placeholders = ",".join("?" for _ in handles)
    sql = f'''
        SELECT
            h.id AS handle,
            m.is_from_me AS is_from_me,
            COALESCE(m.text, '') AS text,
            datetime(m.date / 1000000000 + 978307200, 'unixepoch', 'localtime') AS ts,
            c.display_name AS chat_name,
            m.service AS service
        FROM message m
        JOIN handle h ON h.ROWID = m.handle_id
        LEFT JOIN chat_message_join cmj ON cmj.message_id = m.ROWID
        LEFT JOIN chat c ON c.ROWID = cmj.chat_id
        WHERE h.id IN ({placeholders})
        ORDER BY ts ASC
    '''
    rows = conn.execute(sql, handles).fetchall()
    conn.close()

    interactions: list[Interaction] = []
    for row in rows:
        text = (row["text"] or "").strip()
        ts = row["ts"]
        if not ts:
            continue
        dt = parse_message_time(ts)
        sentiment, score = score_sentiment(text)
        interactions.append(
            Interaction(
                source="messages",
                timestamp=dt.isoformat(sep=" "),
                date=dt.strftime("%Y-%m-%d"),
                time=dt.strftime("%H:%M:%S"),
                direction="outbound" if row["is_from_me"] else "inbound",
                counterpart=row["handle"],
                text=text,
                sentiment=sentiment,
                score=score,
                meta={
                    "chat_name": row["chat_name"],
                    "service": row["service"],
                },
            )
        )
    return interactions


def find_email_candidates(name_terms: list[str]) -> list[str]:
    if not MAIL_ENVELOPE.exists():
        return []
    conn = sqlite3.connect(MAIL_ENVELOPE)
    clauses = []
    params: list[str] = []
    for term in name_terms:
        clauses.append("lower(address) LIKE ?")
        params.append(f"%{term.lower()}%")
        clauses.append("lower(comment) LIKE ?")
        params.append(f"%{term.lower()}%")
    sql = f"SELECT DISTINCT address FROM addresses WHERE {' OR '.join(clauses)}"
    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return sorted({row[0] for row in rows if row and row[0]})


def iter_emlx_files() -> list[Path]:
    return list(MAIL_ROOT.rglob("*.emlx"))


def extract_email_text(msg) -> str:
    if msg.is_multipart():
        parts = []
        for part in msg.walk():
            ctype = part.get_content_type()
            disp = str(part.get("Content-Disposition", ""))
            if ctype == "text/plain" and "attachment" not in disp:
                try:
                    parts.append(part.get_content())
                except Exception:
                    pass
        return "\n".join(p.strip() for p in parts if p).strip()
    try:
        return str(msg.get_content()).strip()
    except Exception:
        return ""


def fetch_emails(addresses: list[str]) -> list[Interaction]:
    if not addresses:
        return []
    address_set = {a.lower() for a in addresses}
    results: list[Interaction] = []
    for path in iter_emlx_files():
        try:
            raw = path.read_bytes()
            split = raw.split(b"\n", 1)
            payload = split[1] if len(split) == 2 and split[0].strip().isdigit() else raw
            msg = BytesParser(policy=policy.default).parsebytes(payload)
            from_addr = str(msg.get("from", ""))
            to_addr = str(msg.get("to", ""))
            cc_addr = str(msg.get("cc", ""))
            haystack = " ".join([from_addr, to_addr, cc_addr]).lower()
            if not any(addr in haystack for addr in address_set):
                continue
            date_hdr = msg.get("date")
            if not date_hdr:
                continue
            try:
                dt = parsedate_to_datetime(date_hdr)
                if dt.tzinfo is not None:
                    dt = dt.astimezone().replace(tzinfo=None)
            except Exception:
                continue
            text = extract_email_text(msg)
            subject = str(msg.get("subject", ""))
            sentiment, score = score_sentiment(text or subject)
            direction = "outbound" if "hello@kaio.email" in from_addr.lower() or "korafz@icloud.com" in from_addr.lower() else "inbound"
            counterpart = from_addr if direction == "inbound" else to_addr
            results.append(
                Interaction(
                    source="mail",
                    timestamp=dt.isoformat(sep=" "),
                    date=dt.strftime("%Y-%m-%d"),
                    time=dt.strftime("%H:%M:%S"),
                    direction=direction,
                    counterpart=counterpart,
                    text=text,
                    sentiment=sentiment,
                    score=score,
                    meta={"subject": subject, "path": str(path)},
                )
            )
        except Exception:
            continue
    results.sort(key=lambda x: x.timestamp)
    return results


def parsedate_to_datetime(value: str) -> datetime:
    from email.utils import parsedate_to_datetime as _p
    return _p(value)


def build_summary(interactions: list[Interaction]) -> dict[str, Any]:
    by_day: dict[str, list[Interaction]] = defaultdict(list)
    counts = {"messages": 0, "mail": 0, "inbound": 0, "outbound": 0}
    sentiments = {"positive": 0, "neutral": 0, "negative": 0}
    for item in interactions:
        by_day[item.date].append(item)
        counts[item.source] += 1
        counts[item.direction] += 1
        sentiments[item.sentiment] += 1
    return {
        "total_interactions": len(interactions),
        "counts": counts,
        "sentiments": sentiments,
        "date_range": {
            "start": interactions[0].timestamp if interactions else None,
            "end": interactions[-1].timestamp if interactions else None,
        },
        "days": {
            day: {
                "count": len(items),
                "sentiments": {
                    "positive": sum(1 for i in items if i.sentiment == "positive"),
                    "neutral": sum(1 for i in items if i.sentiment == "neutral"),
                    "negative": sum(1 for i in items if i.sentiment == "negative"),
                },
            }
            for day, items in sorted(by_day.items())
        },
    }


def write_markdown(path: Path, person: str, handles: list[str], emails: list[str], interactions: list[Interaction], summary: dict[str, Any]) -> None:
    lines: list[str] = []
    lines.append(f"# Relationship dossier: {person}")
    lines.append("")
    lines.append("## Resolved identities")
    lines.append("")
    lines.append(f"- message handles: {', '.join(handles) if handles else 'none found'}")
    lines.append(f"- email addresses: {', '.join(emails) if emails else 'none found'}")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- total interactions: {summary['total_interactions']}")
    lines.append(f"- messages: {summary['counts']['messages']}")
    lines.append(f"- emails: {summary['counts']['mail']}")
    lines.append(f"- inbound: {summary['counts']['inbound']}")
    lines.append(f"- outbound: {summary['counts']['outbound']}")
    lines.append(f"- positive: {summary['sentiments']['positive']}")
    lines.append(f"- neutral: {summary['sentiments']['neutral']}")
    lines.append(f"- negative: {summary['sentiments']['negative']}")
    lines.append(f"- range: {summary['date_range']['start']} -> {summary['date_range']['end']}")
    lines.append("")
    lines.append("## Timeline")
    lines.append("")
    current_day = None
    for item in interactions:
        if item.date != current_day:
            current_day = item.date
            lines.append(f"### {current_day}")
            lines.append("")
        preview = item.text.replace("\n", " ").strip()
        if len(preview) > 220:
            preview = preview[:217] + "..."
        lines.append(
            f"- {item.time} | {item.source} | {item.direction} | {item.sentiment} ({item.score}) | {preview or '[no text]'}"
        )
    path.write_text("\n".join(lines) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build a relationship dossier from Messages and Mail")
    parser.add_argument("person", help="Person label, e.g. 'Chuck Werley'")
    parser.add_argument("--message-handle", action="append", default=[], help="Explicit iMessage/SMS handle")
    parser.add_argument("--email", action="append", default=[], help="Explicit email address")
    args = parser.parse_args()

    slug = slugify(args.person)
    out_dir = ROOT / slug
    out_dir.mkdir(parents=True, exist_ok=True)

    handles = list(dict.fromkeys(args.message_handle + resolve_contacts(args.person)))
    name_terms = [part for part in re.split(r"[^a-zA-Z0-9]+", args.person) if part]
    emails = list(dict.fromkeys(args.email + find_email_candidates(name_terms)))

    interactions = fetch_imessages(handles) + fetch_emails(emails)
    interactions.sort(key=lambda x: x.timestamp)
    summary = build_summary(interactions)

    json_path = out_dir / "dossier.json"
    md_path = out_dir / "dossier.md"
    json_path.write_text(json.dumps({
        "person": args.person,
        "handles": handles,
        "emails": emails,
        "summary": summary,
        "interactions": [asdict(i) for i in interactions],
    }, indent=2))
    write_markdown(md_path, args.person, handles, emails, interactions, summary)

    print(json.dumps({
        "person": args.person,
        "output_dir": str(out_dir),
        "json": str(json_path),
        "markdown": str(md_path),
        "handles": handles,
        "emails": emails,
        "total_interactions": len(interactions),
    }, indent=2))


if __name__ == "__main__":
    main()
