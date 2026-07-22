#!/usr/bin/env python3

import argparse
import email
import json
import re
from email import policy
from html import unescape
from pathlib import Path


def clean_html(value: str) -> str:
    value = re.sub(r"(?is)<(script|style).*?>.*?</\1>", " ", value)
    value = re.sub(r"(?i)<br\s*/?>", "\n", value)
    value = re.sub(r"(?i)</(p|div|li|tr|h[1-6])>", "\n", value)
    value = re.sub(r"(?s)<[^>]+>", " ", value)
    value = unescape(value)
    return normalize_text(value)


def normalize_text(value: str) -> str:
    value = value.replace("\r\n", "\n").replace("\r", "\n")
    value = re.sub(r"[ \t]+", " ", value)
    value = re.sub(r" *\n *", "\n", value)
    value = re.sub(r"\n{3,}", "\n\n", value)
    return value.strip()


def decode_part(part: email.message.Message) -> str:
    try:
        return part.get_content()
    except Exception:
        payload = part.get_payload(decode=True) or b""
        return payload.decode(part.get_content_charset() or "utf-8", errors="replace")


def parse_emlx(path: Path) -> dict:
    raw = path.read_bytes()
    first_newline = raw.find(b"\n")
    if first_newline > 0 and raw[:first_newline].strip().isdigit():
        raw = raw[first_newline + 1 :]
    message = email.message_from_bytes(raw, policy=policy.default)

    plain_parts = []
    html_parts = []
    attachments = []
    for part in message.walk():
        if part.is_multipart():
            continue
        content_type = part.get_content_type()
        disposition = part.get_content_disposition()
        filename = part.get_filename()
        if disposition == "attachment" or filename:
            attachments.append(
                {
                    "filename": filename,
                    "content_type": content_type,
                    "size": len(part.get_payload(decode=True) or b""),
                }
            )
            continue
        if content_type == "text/plain":
            plain_parts.append(normalize_text(decode_part(part)))
        elif content_type == "text/html":
            html_parts.append(clean_html(decode_part(part)))

    body = "\n\n".join(part for part in plain_parts if part)
    if not body:
        body = "\n\n".join(part for part in html_parts if part)
    body = body.split('<?xml version="1.0"', 1)[0].strip()

    return {
        "path": str(path),
        "message_id": message.get("Message-ID"),
        "date": message.get("Date"),
        "from": message.get("From"),
        "to": message.get("To"),
        "cc": message.get("Cc"),
        "reply_to": message.get("Reply-To"),
        "subject": message.get("Subject"),
        "in_reply_to": message.get("In-Reply-To"),
        "references": message.get("References"),
        "body": body,
        "attachments": attachments,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+")
    args = parser.parse_args()
    records = [parse_emlx(Path(path)) for path in args.paths]
    print(json.dumps(records, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
