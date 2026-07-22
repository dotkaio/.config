#!/usr/bin/env python3

import csv
import json
import re
from collections import Counter
from pathlib import Path


SOURCE = Path(
    "/Users/kaioferraz/Documents/Developer/analysis/messages/"
    "2026-07-06_10-56-00/messages_with_sentiment.csv"
)
TARGETS = {"+15106762344", "+14082441111"}
WORK_JSON = Path(
    "/Users/kaioferraz/Documents/Codex/2026-07-14/"
    "go-over-all-my-messages-with/work/bossini_messages.json"
)
TRANSCRIPT = Path(
    "/Users/kaioferraz/Documents/Codex/2026-07-14/"
    "go-over-all-my-messages-with/outputs/bossini_messages_transcript.md"
)


def redact(text: str) -> str:
    text = re.sub(
        r"(?i)(password|passcode|p\.s\.)\s*[:=-]?\s*([^\s,;]+)",
        lambda match: f"{match.group(1)}: [REDACTED CREDENTIAL]",
        text,
    )
    text = re.sub(
        r"(?i)(login)\s*:\s*([^\s,;]+)",
        lambda match: f"{match.group(1)}: [REDACTED CREDENTIAL]",
        text,
    )
    return text


with SOURCE.open(newline="", encoding="utf-8-sig") as source_file:
    reader = csv.DictReader(source_file)
    rows = [row for row in reader if row["chat_identifier"] in TARGETS]

rows.sort(key=lambda row: (row["datetime"], int(row["message_id"])))
WORK_JSON.write_text(json.dumps(rows, indent=2, ensure_ascii=False), encoding="utf-8")

counts = Counter(row["chat_identifier"] for row in rows)
direction_counts = Counter(row["direction"] for row in rows)
nonempty = sum(bool(row["text"].strip()) for row in rows)
attachments = sum(row["has_attachments"] == "1" for row in rows)

lines = [
    "# Bossini / Anjum Messages transcript",
    "",
    "This is a chronological, read-only extraction from the local Messages analysis snapshot created July 6, 2026. It is not the live Messages database. Credential-like strings are redacted; original message IDs and GUIDs are retained for traceability.",
    "",
    "## Coverage",
    "",
    f"- Total rows: {len(rows)}",
    f"- Non-empty message rows: {nonempty}",
    f"- Rows with attachments: {attachments}",
    f"- Outbound: {direction_counts['outbound']}",
    f"- Inbound: {direction_counts['inbound']}",
    f"- +1 (510) 676-2344: {counts['+15106762344']}",
    f"- +1 (408) 244-1111: {counts['+14082441111']}",
    f"- First timestamp: {rows[0]['datetime'] if rows else 'none'}",
    f"- Last timestamp: {rows[-1]['datetime'] if rows else 'none'}",
    "",
    "## Transcript",
    "",
]

for row in rows:
    speaker = "Kaio" if row["direction"] == "outbound" else "Anjum / Bossini"
    text = redact(row["text"].strip()) or "[No extracted text]"
    flags = []
    if row["has_attachments"] == "1":
        flags.append("attachment")
    if row["is_system_message"] == "1":
        flags.append("system")
    if row["associated_message_type"] != "0":
        flags.append(f"associated_type={row['associated_message_type']}")
    suffix = f" ({', '.join(flags)})" if flags else ""
    lines.extend(
        [
            f"### {row['datetime']} — {speaker}{suffix}",
            "",
            text,
            "",
            f"Evidence ID: message_id `{row['message_id']}`, GUID `{row['message_guid']}`.",
            "",
        ]
    )

TRANSCRIPT.write_text("\n".join(lines), encoding="utf-8")

print(
    json.dumps(
        {
            "total": len(rows),
            "nonempty": nonempty,
            "attachments": attachments,
            "directions": direction_counts,
            "handles": counts,
            "first": rows[0]["datetime"] if rows else None,
            "last": rows[-1]["datetime"] if rows else None,
            "work_json": str(WORK_JSON),
            "transcript": str(TRANSCRIPT),
        },
        indent=2,
        default=dict,
    )
)
