#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.parse
from html import unescape


def _norm_phone(s: str):
    if not s:
        return None
    s = str(s)
    leading_plus = s.strip().startswith("+")
    digits = re.sub(r"\D", "", s)
    if not digits:
        return None
    return ("+" if leading_plus else "") + digits


def _escape_vcard(s: str) -> str:
    # vCard escaping: backslash, comma, semicolon, and newline.
    s = s or ""
    s = s.replace("\\", "\\\\")
    s = s.replace("\n", "\\n")
    s = s.replace(",", "\\,")
    s = s.replace(";", "\\;")
    return s


def _build_vcard(name: str, phones: list[str], emails: list[str], photo_url: str, note: str) -> str:
    # Minimal vCard 3.0.
    safe_name = name.strip() or "Person"
    lines = [
        "BEGIN:VCARD",
        "VERSION:3.0",
        f"FN:{_escape_vcard(safe_name)}",
        f"N:{_escape_vcard(safe_name)};;;;",
    ]
    for p in phones:
        p = _norm_phone(p)
        if not p:
            continue
        # Use CELL as a best-effort; Contacts will still accept it.
        lines.append(f"TEL;TYPE=CELL:{_escape_vcard(p)}")

    for e in emails:
        e = (e or "").strip()
        if not e:
            continue
        lines.append(f"EMAIL;TYPE=INTERNET:{_escape_vcard(e)}")

    photo_url = (photo_url or "").strip()
    if photo_url.startswith("http://") or photo_url.startswith("https://"):
        # Contacts can import PHOTO by URL in most cases.
        lines.append(f"PHOTO;VALUE=URL:{_escape_vcard(photo_url)}")
    note = note.strip()
    if note:
        lines.append(f"NOTE:{_escape_vcard(note)}")
    lines.append("END:VCARD")
    return "\r\n".join(lines) + "\r\n"


def _import_vcard(vcf_path: str) -> bool:
    # Try AppleScript import first.
    # Keep this AppleScript minimal: if Contacts can't import it, osascript will fail.
    applescript = f'''
tell application "Contacts"
  import vCard from (POSIX file "{vcf_path}")
end tell
'''

    try:
        tmp_applescript = tempfile.NamedTemporaryFile(
            mode="w", suffix=".applescript", prefix="enformion_import_", delete=False, encoding="utf-8"
        )
        tmp_applescript.write(applescript)
        tmp_applescript.flush()
        tmp_applescript_path = tmp_applescript.name
        tmp_applescript.close()

        r = subprocess.run(
            ["osascript", tmp_applescript_path],
            check=False,
            capture_output=True,
            text=True,
        )
        ok = r.returncode == 0
        try:
            os.unlink(tmp_applescript_path)
        except Exception:
            pass
        return ok
    except Exception:
        return False


def main():
    if len(sys.argv) < 2:
        print("Usage: enformion_merge_contacts.py <json_path>", file=sys.stderr)
        return 2

    json_path = sys.argv[1]
    if not os.path.exists(json_path):
        print(f"Missing json file: {json_path}", file=sys.stderr)
        return 2

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    name = data.get("name") or "Person"
    phones = data.get("phones") or []
    emails = data.get("emails") or []
    biography = data.get("biography") or ""
    ai_analysis = data.get("ai_analysis") or ""
    social_urls = data.get("social_urls") or []
    photo_url = data.get("photo_url") or ""

    note = ""
    if biography.strip():
        note += biography.strip()
    if ai_analysis.strip():
        note += ("\n\n" if note else "") + "Summary:\n" + ai_analysis.strip()

    if social_urls:
        note += ("\n\n" if note else "") + "Social:\n"
        for u in social_urls[:8]:
            note += f"- {u}\n"

    vcard = _build_vcard(
        name=name,
        phones=phones,
        emails=emails,
        photo_url=photo_url,
        note=note,
    )

    tmpdir = tempfile.mkdtemp(prefix="enformion_vcard_")
    vcf_path = os.path.join(tmpdir, "contact.vcf")
    with open(vcf_path, "w", encoding="utf-8") as f:
        f.write(vcard)

    ok = _import_vcard(vcf_path)
    if not ok:
        # Fallback: open vCard so the user can import.
        subprocess.run(["open", vcf_path], check=False)
        print("CONTACT_IMPORT_FALLBACK=opened vcf")
        return 1

    print("CONTACT_IMPORT_OK=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
