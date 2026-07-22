#!/usr/bin/env python3

from email.utils import parsedate_to_datetime
from pathlib import Path

from extract_emlx import parse_emlx


MAIL_ROOT = Path("/Users/kaioferraz/Library/Mail/V10")
OUTPUT = Path(
    "/Users/kaioferraz/Documents/Codex/2026-07-14/"
    "go-over-all-my-messages-with/outputs/bossini_email_transcript.md"
)
NEEDLES = (
    b"bossini.usa@gmail.com",
    b"anjumrsandhu@gmail.com",
    b"Anjum Sandhu",
    b"408-244-1111",
)


paths = []
for path in MAIL_ROOT.rglob("*.emlx"):
    raw = path.read_bytes()
    if any(needle.lower() in raw.lower() for needle in NEEDLES):
        paths.append(path)

records = [parse_emlx(path) for path in paths]
records.sort(key=lambda record: parsedate_to_datetime(record["date"]))

lines = [
    "# Bossini / Anjum email transcript",
    "",
    "This is a chronological, read-only extraction from the local Apple Mail store. It includes messages matching Bossini's email, Anjum's personal email, his name, or the supplied business phone number.",
    "",
    "## Coverage",
    "",
    f"- Total matching emails: {len(records)}",
    f"- First email: {records[0]['date'] if records else 'none'}",
    f"- Last email: {records[-1]['date'] if records else 'none'}",
    "",
    "## Transcript",
    "",
]

for record in records:
    lines.extend(
        [
            f"### {record['date']} - {record['subject']}",
            "",
            f"From: {record['from']}",
            "",
            f"To: {record['to']}",
            "",
        ]
    )
    if record["cc"]:
        lines.extend([f"Cc: {record['cc']}", ""])
    lines.extend([record["body"] or "[No extracted body text]", ""])
    if record["attachments"]:
        lines.extend(
            [
                "Attachments referenced:",
                "",
                *[
                    f"- {attachment['filename'] or '[unnamed]'} ({attachment['content_type']})"
                    for attachment in record["attachments"]
                ],
                "",
            ]
        )
    lines.extend(
        [
            f"Evidence: Message-ID `{record['message_id']}`; local file `{record['path']}`.",
            "",
        ]
    )

OUTPUT.write_text("\n".join(lines), encoding="utf-8")
print(f"Wrote {OUTPUT} with {len(records)} emails")
