#!/usr/bin/env python3
import csv
import datetime as dt
import html
import json
import math
import os
import re
import sqlite3
import statistics
from collections import Counter, defaultdict
from pathlib import Path


DB_PATH = Path("/Users/kaioferraz/Library/Messages/chat.db")
DESKTOP = Path("/Users/kaioferraz/Desktop")


POSITIVE = {
    "accept": 1.3, "accepted": 1.5, "amazing": 2.5, "appreciate": 2.0, "awesome": 2.4,
    "beautiful": 2.1, "best": 2.0, "better": 1.1, "blessed": 2.0, "brilliant": 2.3,
    "calm": 1.2, "care": 1.0, "cheers": 1.3, "clean": 0.8, "clear": 0.7,
    "congrats": 2.2, "cool": 1.5, "deal": 0.7, "done": 1.0, "easy": 1.1,
    "enjoy": 1.8, "excellent": 2.5, "excited": 2.1, "fair": 0.8, "fast": 0.7,
    "fine": 0.6, "fun": 1.8, "glad": 1.8, "good": 1.6, "great": 2.2,
    "haha": 1.2, "happy": 2.1, "helpful": 1.4, "hope": 1.0, "impressive": 2.0,
    "kind": 1.2, "like": 1.1, "lol": 1.0, "love": 2.6, "nice": 1.8,
    "ok": 0.3, "okay": 0.3, "perfect": 2.4, "pleasure": 1.8, "positive": 1.4,
    "ready": 0.8, "resolved": 1.3, "respect": 1.5, "right": 0.7, "solid": 1.5,
    "sure": 0.5, "thanks": 1.7, "thank": 1.7, "thrilled": 2.4, "trust": 1.4,
    "understand": 0.8, "win": 1.8, "winning": 1.8, "works": 1.0, "yes": 0.8,
}


NEGATIVE = {
    "afraid": -1.8, "angry": -2.2, "annoyed": -1.8, "anxious": -1.9, "awful": -2.5,
    "bad": -1.8, "blocked": -1.2, "broke": -1.6, "broken": -1.8, "busy": -0.7,
    "cancel": -1.2, "confused": -1.4, "crazy": -1.0, "crisis": -2.3, "damage": -1.8,
    "damn": -1.4, "dead": -1.9, "delay": -1.0, "delayed": -1.0, "difficult": -1.1,
    "disappointed": -2.2, "doubt": -1.2, "emergency": -2.3, "error": -1.4, "fail": -1.9,
    "failed": -1.9, "failure": -2.0, "fear": -1.9, "fight": -1.7, "frustrated": -2.0,
    "fuck": -2.0, "hate": -2.5, "hard": -0.8, "hurt": -2.0, "issue": -1.0,
    "late": -0.9, "lost": -1.3, "mad": -1.7, "mess": -1.3, "miss": -0.8,
    "missing": -1.0, "never": -0.8, "no": -0.6, "nope": -0.7, "not": -0.4,
    "pain": -2.0, "problem": -1.4, "refuse": -1.3, "reject": -1.5, "rejected": -1.8,
    "risk": -1.1, "sad": -2.0, "scam": -2.2, "shit": -1.8, "sorry": -0.7,
    "stress": -1.8, "stressed": -1.9, "stuck": -1.3, "terrible": -2.5, "tired": -1.2,
    "trouble": -1.5, "unhappy": -2.0, "urgent": -1.0, "wrong": -1.6, "wtf": -1.8,
}


STOPWORDS = {
    "a", "about", "after", "all", "also", "am", "an", "and", "any", "are", "as", "at",
    "be", "because", "been", "but", "by", "can", "could", "did", "do", "does", "doing",
    "done", "for", "from", "get", "go", "going", "got", "had", "has", "have", "he",
    "her", "here", "him", "his", "how", "i", "if", "im", "in", "is", "it", "its",
    "just", "know", "like", "me", "my", "need", "no", "not", "now", "of", "on", "or",
    "our", "out", "over", "right", "see", "she", "so", "that", "the", "their", "them",
    "then", "there", "they", "this", "to", "too", "up", "us", "was", "we", "were",
    "what", "when", "where", "which", "who", "why", "will", "with", "would", "yeah",
    "yes", "you", "your", "youre", "u", "ur", "lol", "haha", "ok", "okay", "https",
    "www", "com", "one", "two", "three", "gonna", "wanna", "dont", "cant", "ill",
}


THEMES = {
    "work_business": {
        "client", "clients", "business", "deal", "invoice", "paid", "pay", "money", "job",
        "project", "meeting", "call", "contract", "website", "app", "agent", "ai", "code",
        "github", "demo", "proposal", "sales", "lead", "leads", "customer", "service",
    },
    "logistics": {
        "today", "tomorrow", "tonight", "morning", "time", "pm", "am", "where", "here",
        "there", "home", "drive", "coming", "arrive", "leaving", "send", "sent", "address",
        "location", "schedule", "available", "free", "later", "soon", "wait",
    },
    "relationships": {
        "love", "miss", "family", "mom", "dad", "friend", "friends", "baby", "bro",
        "brother", "sister", "heart", "care", "feel", "felt", "sorry", "happy",
    },
    "conflict_stress": {
        "problem", "issue", "wrong", "bad", "sorry", "stress", "stressed", "urgent", "late",
        "angry", "mad", "hurt", "fight", "confused", "blocked", "cancel", "emergency",
    },
    "planning": {
        "plan", "plans", "idea", "think", "maybe", "should", "could", "want", "need",
        "next", "start", "build", "create", "make", "finish", "fix", "review",
    },
}


TOKEN_RE = re.compile(r"[a-zA-Z][a-zA-Z']+|[0-9]+(?:\.[0-9]+)?")
URL_RE = re.compile(r"https?://\S+|www\.\S+")
CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]")


def apple_time_to_datetime(value):
    if value is None:
        return None
    try:
        raw = int(value)
    except (TypeError, ValueError):
        return None
    if raw == 0:
        return None
    seconds = raw / 1_000_000_000 if abs(raw) > 10_000_000_000 else raw
    base = dt.datetime(2001, 1, 1, tzinfo=dt.timezone.utc)
    return base + dt.timedelta(seconds=seconds)


def decode_attributed_body(blob):
    if not blob:
        return ""
    try:
        decoded = blob.decode("utf-8", errors="ignore")
    except AttributeError:
        return ""
    if not decoded:
        return ""
    candidates = []
    if "NSString" in decoded:
        tail = decoded.split("NSString", 1)[1]
        for marker in ("NSDictionary", "NSColor", "NSFont", "NSObject", "NSNumber"):
            if marker in tail:
                tail = tail.split(marker, 1)[0]
        candidates.append(tail)
    candidates.append(decoded)
    for candidate in candidates:
        cleaned = CONTROL_RE.sub(" ", candidate)
        cleaned = re.sub(r"\s+", " ", cleaned).strip()
        cleaned = cleaned.strip(" +_-$#@!~^*()[]{};:'\",.<>?/\\|`")
        if len(cleaned) >= 2 and not cleaned.startswith("streamtyped"):
            return cleaned
    return ""


def normalize_text(text):
    if not text:
        return ""
    text = html.unescape(text)
    text = text.replace("\u2028", " ").replace("\u2029", " ")
    text = CONTROL_RE.sub(" ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def clean_contact(value):
    if not value:
        return "(unknown)"
    return value.replace("\n", " ").strip()


def tokens(text):
    return [t.lower().replace("'", "") for t in TOKEN_RE.findall(URL_RE.sub(" ", text or ""))]


def sentiment(text):
    toks = tokens(text)
    if not toks:
        return 0.0, "neutral"
    total = 0.0
    hits = 0
    negate = False
    for idx, tok in enumerate(toks):
        val = POSITIVE.get(tok, NEGATIVE.get(tok, 0.0))
        if tok in {"not", "no", "never", "dont", "cant", "wont", "isnt", "wasnt"}:
            negate = True
            continue
        if val:
            if negate:
                val *= -0.75
                negate = False
            if idx > 0 and toks[idx - 1] in {"very", "really", "so", "super", "too"}:
                val *= 1.25
            total += val
            hits += 1
    lower = (text or "").lower()
    total += lower.count("❤️") * 2.0 + lower.count("😂") * 1.3 + lower.count("🤣") * 1.4
    total += lower.count("😡") * -2.0 + lower.count("😭") * -1.4 + lower.count("😢") * -1.6
    if "!" in text and total:
        total *= 1.08
    score = total / math.sqrt(max(len(toks), 1))
    score = max(-5.0, min(5.0, score))
    if score >= 0.35:
        label = "positive"
    elif score <= -0.35:
        label = "negative"
    else:
        label = "neutral"
    return round(score, 4), label


def pct(n, d):
    return round((n / d) * 100, 2) if d else 0.0


def median(values):
    return round(statistics.median(values), 2) if values else None


def mean(values):
    return round(statistics.mean(values), 4) if values else None


def top_terms(texts, n=60, min_count=3):
    unigram = Counter()
    bigram = Counter()
    trigram = Counter()
    for text in texts:
        ts = [t for t in tokens(text) if len(t) > 2 and t not in STOPWORDS]
        unigram.update(ts)
        bigram.update(" ".join(pair) for pair in zip(ts, ts[1:]))
        trigram.update(" ".join(tri) for tri in zip(ts, ts[1:], ts[2:]))
    combined = []
    for label, counter in (("term", unigram), ("phrase2", bigram), ("phrase3", trigram)):
        for term, count in counter.most_common(n * 3):
            if count >= min_count:
                combined.append({"type": label, "text": term, "count": count})
    combined.sort(key=lambda x: (x["count"], len(x["text"])), reverse=True)
    return combined[:n]


def theme_counts(text):
    ts = set(tokens(text))
    return {theme: len(words & ts) for theme, words in THEMES.items()}


def read_rows():
    uri = f"file:{DB_PATH}?mode=ro"
    con = sqlite3.connect(uri, uri=True)
    con.row_factory = sqlite3.Row
    query = """
        SELECT
            m.ROWID AS message_id,
            m.guid AS message_guid,
            m.text AS text,
            m.attributedBody AS attributed_body,
            m.service AS message_service,
            m.date AS message_date,
            m.date_read AS date_read,
            m.date_delivered AS date_delivered,
            m.is_from_me AS is_from_me,
            m.is_read AS is_read,
            m.is_sent AS is_sent,
            m.is_delivered AS is_delivered,
            m.cache_has_attachments AS has_attachments,
            m.is_system_message AS is_system_message,
            m.associated_message_type AS associated_message_type,
            h.id AS handle_id_text,
            h.service AS handle_service,
            c.ROWID AS chat_id,
            c.guid AS chat_guid,
            c.chat_identifier AS chat_identifier,
            c.display_name AS display_name,
            c.service_name AS chat_service,
            c.room_name AS room_name,
            c.style AS chat_style
        FROM message m
        LEFT JOIN handle h ON h.ROWID = m.handle_id
        LEFT JOIN chat_message_join cmj ON cmj.message_id = m.ROWID
        LEFT JOIN chat c ON c.ROWID = cmj.chat_id
        ORDER BY m.date ASC, m.ROWID ASC
    """
    rows = []
    seen = set()
    for row in con.execute(query):
        key = (row["message_id"], row["chat_id"])
        if key in seen:
            continue
        seen.add(key)
        text = normalize_text(row["text"]) or normalize_text(decode_attributed_body(row["attributed_body"]))
        when = apple_time_to_datetime(row["message_date"])
        local_when = when.astimezone() if when else None
        chat_name = row["display_name"] or row["chat_identifier"] or row["room_name"] or row["handle_id_text"] or "(unknown chat)"
        rows.append({
            "message_id": row["message_id"],
            "message_guid": row["message_guid"],
            "chat_id": row["chat_id"] if row["chat_id"] is not None else -1,
            "chat_name": clean_contact(chat_name),
            "chat_identifier": clean_contact(row["chat_identifier"]),
            "contact": "me" if row["is_from_me"] else clean_contact(row["handle_id_text"]),
            "direction": "outbound" if row["is_from_me"] else "inbound",
            "service": row["message_service"] or row["chat_service"] or row["handle_service"] or "",
            "datetime": local_when.isoformat(timespec="seconds") if local_when else "",
            "date": local_when.date().isoformat() if local_when else "",
            "hour": local_when.hour if local_when else "",
            "weekday": local_when.strftime("%A") if local_when else "",
            "is_from_me": int(row["is_from_me"] or 0),
            "is_read": int(row["is_read"] or 0),
            "is_sent": int(row["is_sent"] or 0),
            "is_delivered": int(row["is_delivered"] or 0),
            "has_attachments": int(row["has_attachments"] or 0),
            "is_system_message": int(row["is_system_message"] or 0),
            "associated_message_type": int(row["associated_message_type"] or 0),
            "text": text,
        })
    con.close()
    return rows


def analyze(rows):
    text_rows = [r for r in rows if r["text"]]
    for row in rows:
        score, label = sentiment(row["text"])
        row["sentiment_score"] = score
        row["sentiment_label"] = label
        row["word_count"] = len(tokens(row["text"]))
        row["char_count"] = len(row["text"])

    chats = defaultdict(list)
    by_day = defaultdict(list)
    by_month = defaultdict(list)
    by_hour = defaultdict(list)
    by_weekday = defaultdict(list)
    by_service = defaultdict(list)
    all_theme_counts = Counter()

    for row in rows:
        chats[row["chat_id"]].append(row)
        if row["date"]:
            by_day[row["date"]].append(row)
            by_month[row["date"][:7]].append(row)
        if row["hour"] != "":
            by_hour[str(row["hour"]).zfill(2)].append(row)
        if row["weekday"]:
            by_weekday[row["weekday"]].append(row)
        by_service[row["service"] or "(unknown)"].append(row)
        all_theme_counts.update(theme_counts(row["text"]))

    chat_summaries = []
    response_samples = []
    for chat_id, items in chats.items():
        items.sort(key=lambda r: (r["datetime"], r["message_id"]))
        scores = [r["sentiment_score"] for r in items if r["text"]]
        outbound = [r for r in items if r["is_from_me"]]
        inbound = [r for r in items if not r["is_from_me"]]
        out_scores = [r["sentiment_score"] for r in outbound if r["text"]]
        in_scores = [r["sentiment_score"] for r in inbound if r["text"]]
        response_to_me = []
        my_response = []
        previous = None
        for current in items:
            if not current["datetime"]:
                continue
            if previous and previous["datetime"] and previous["is_from_me"] != current["is_from_me"]:
                try:
                    prev_dt = dt.datetime.fromisoformat(previous["datetime"])
                    curr_dt = dt.datetime.fromisoformat(current["datetime"])
                except ValueError:
                    previous = current
                    continue
                minutes = (curr_dt - prev_dt).total_seconds() / 60
                if 0 <= minutes <= 60 * 24 * 7:
                    if current["is_from_me"]:
                        my_response.append(minutes)
                    else:
                        response_to_me.append(minutes)
                    response_samples.append({
                        "chat_id": chat_id,
                        "chat_name": current["chat_name"],
                        "responder": "me" if current["is_from_me"] else "them",
                        "minutes": round(minutes, 2),
                        "previous_datetime": previous["datetime"],
                        "response_datetime": current["datetime"],
                    })
            previous = current
        first_dt = next((r["datetime"] for r in items if r["datetime"]), "")
        last_dt = next((r["datetime"] for r in reversed(items) if r["datetime"]), "")
        chat_terms = top_terms([r["text"] for r in items if r["text"]], n=12, min_count=2)
        theme_total = Counter()
        for r in items:
            theme_total.update(theme_counts(r["text"]))
        chat_summaries.append({
            "chat_id": chat_id,
            "chat_name": items[-1]["chat_name"],
            "chat_identifier": items[-1]["chat_identifier"],
            "messages": len(items),
            "text_messages": sum(1 for r in items if r["text"]),
            "outbound": len(outbound),
            "inbound": len(inbound),
            "outbound_pct": pct(len(outbound), len(items)),
            "avg_sentiment": mean(scores),
            "avg_my_sentiment": mean(out_scores),
            "avg_their_sentiment": mean(in_scores),
            "positive_pct": pct(sum(1 for r in items if r["sentiment_label"] == "positive"), len(items)),
            "negative_pct": pct(sum(1 for r in items if r["sentiment_label"] == "negative"), len(items)),
            "median_my_response_minutes": median(my_response),
            "median_their_response_minutes": median(response_to_me),
            "first_message": first_dt,
            "last_message": last_dt,
            "top_terms": "; ".join(f'{t["text"]} ({t["count"]})' for t in chat_terms[:8]),
            "dominant_theme": theme_total.most_common(1)[0][0] if theme_total else "",
            "theme_hits": dict(theme_total),
        })

    chat_summaries.sort(key=lambda x: x["messages"], reverse=True)

    def aggregate_bucket(bucket):
        output = []
        for name, items in bucket.items():
            scores = [r["sentiment_score"] for r in items if r["text"]]
            output.append({
                "bucket": name,
                "messages": len(items),
                "outbound": sum(1 for r in items if r["is_from_me"]),
                "inbound": sum(1 for r in items if not r["is_from_me"]),
                "avg_sentiment": mean(scores),
                "positive_pct": pct(sum(1 for r in items if r["sentiment_label"] == "positive"), len(items)),
                "negative_pct": pct(sum(1 for r in items if r["sentiment_label"] == "negative"), len(items)),
            })
        return sorted(output, key=lambda x: x["bucket"])

    overall_scores = [r["sentiment_score"] for r in text_rows]
    summary = {
        "generated_at": dt.datetime.now().astimezone().isoformat(timespec="seconds"),
        "database": str(DB_PATH),
        "total_message_rows": len(rows),
        "messages_with_text": len(text_rows),
        "outbound_messages": sum(1 for r in rows if r["is_from_me"]),
        "inbound_messages": sum(1 for r in rows if not r["is_from_me"]),
        "unique_chats": len(chats),
        "date_range": {
            "first": next((r["datetime"] for r in rows if r["datetime"]), ""),
            "last": next((r["datetime"] for r in reversed(rows) if r["datetime"]), ""),
        },
        "sentiment": {
            "avg_score": mean(overall_scores),
            "positive_messages": sum(1 for r in rows if r["sentiment_label"] == "positive"),
            "neutral_messages": sum(1 for r in rows if r["sentiment_label"] == "neutral"),
            "negative_messages": sum(1 for r in rows if r["sentiment_label"] == "negative"),
            "positive_pct": pct(sum(1 for r in rows if r["sentiment_label"] == "positive"), len(rows)),
            "negative_pct": pct(sum(1 for r in rows if r["sentiment_label"] == "negative"), len(rows)),
        },
        "top_terms": top_terms([r["text"] for r in text_rows], n=80, min_count=6),
        "theme_counts": dict(all_theme_counts),
        "top_chats": chat_summaries[:50],
        "monthly": aggregate_bucket(by_month),
        "daily": aggregate_bucket(by_day),
        "hourly": aggregate_bucket(by_hour),
        "weekday": aggregate_bucket(by_weekday),
        "service": aggregate_bucket(by_service),
        "response_samples": response_samples[:20000],
    }
    return summary, chat_summaries


def write_csv(path, rows, fields):
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def markdown_report(summary, chat_summaries):
    top_chats = chat_summaries[:15]
    most_negative = sorted(
        [c for c in chat_summaries if c["messages"] >= 10 and c["avg_sentiment"] is not None],
        key=lambda c: c["avg_sentiment"],
    )[:10]
    most_positive = sorted(
        [c for c in chat_summaries if c["messages"] >= 10 and c["avg_sentiment"] is not None],
        key=lambda c: c["avg_sentiment"],
        reverse=True,
    )[:10]
    asymmetry = sorted(
        [c for c in chat_summaries if c["messages"] >= 20],
        key=lambda c: abs(c["outbound_pct"] - 50),
        reverse=True,
    )[:10]
    hour_rows = sorted(summary["hourly"], key=lambda r: r["messages"], reverse=True)[:5]
    weekday_rows = sorted(summary["weekday"], key=lambda r: r["messages"], reverse=True)
    theme_rows = Counter(summary["theme_counts"]).most_common()

    lines = []
    lines.append("# Messages Pattern Analysis")
    lines.append("")
    lines.append(f"Generated: {summary['generated_at']}")
    lines.append(f"Database: `{summary['database']}`")
    lines.append("")
    lines.append("## Scope")
    lines.append("")
    lines.append(f"- Message rows analyzed: {summary['total_message_rows']:,}")
    lines.append(f"- Messages with extractable text: {summary['messages_with_text']:,}")
    lines.append(f"- Unique chats: {summary['unique_chats']:,}")
    lines.append(f"- Date range: {summary['date_range']['first']} to {summary['date_range']['last']}")
    lines.append(f"- Outbound / inbound: {summary['outbound_messages']:,} / {summary['inbound_messages']:,}")
    lines.append("")
    lines.append("## Overall Sentiment")
    lines.append("")
    sent = summary["sentiment"]
    lines.append(f"- Average score: {sent['avg_score']}")
    lines.append(f"- Positive: {sent['positive_messages']:,} ({sent['positive_pct']}%)")
    lines.append(f"- Negative: {sent['negative_messages']:,} ({sent['negative_pct']}%)")
    lines.append(f"- Neutral: {sent['neutral_messages']:,}")
    lines.append("")
    lines.append("## Patterns You May Not Notice")
    lines.append("")
    if summary["outbound_messages"] > summary["inbound_messages"] * 1.15:
        lines.append("- You send materially more messages than you receive. That usually means you drive logistics, clarification, and follow-up in a large share of threads.")
    elif summary["inbound_messages"] > summary["outbound_messages"] * 1.15:
        lines.append("- You receive materially more messages than you send. That usually means many threads are demand/inbound-heavy and you answer selectively.")
    else:
        lines.append("- Your overall send/receive balance is close to even, so asymmetry is more chat-specific than global.")
    if hour_rows:
        peak = ", ".join(f"{r['bucket']}:00 ({r['messages']:,})" for r in hour_rows[:3])
        lines.append(f"- Your highest-volume texting hours are {peak}. These are your default coordination windows.")
    if weekday_rows:
        top_weekdays = ", ".join(f"{r['bucket']} ({r['messages']:,})" for r in weekday_rows[:3])
        lines.append(f"- Your busiest weekdays are {top_weekdays}.")
    if theme_rows:
        themes = ", ".join(f"{name.replace('_', ' ')} ({count:,})" for name, count in theme_rows[:4])
        lines.append(f"- Dominant themes by keyword signal: {themes}.")
    if asymmetry:
        lines.append(f"- The most one-sided high-volume thread is `{asymmetry[0]['chat_name']}` at {asymmetry[0]['outbound_pct']}% outbound across {asymmetry[0]['messages']:,} messages.")
    if most_negative:
        lines.append(f"- The lowest-sentiment recurring thread is `{most_negative[0]['chat_name']}` with average sentiment {most_negative[0]['avg_sentiment']} across {most_negative[0]['messages']:,} messages.")
    if most_positive:
        lines.append(f"- The highest-sentiment recurring thread is `{most_positive[0]['chat_name']}` with average sentiment {most_positive[0]['avg_sentiment']} across {most_positive[0]['messages']:,} messages.")
    lines.append("")
    lines.append("## Top Chats")
    lines.append("")
    lines.append("| Chat | Messages | Outbound % | Avg sentiment | My median response | Their median response | Dominant theme |")
    lines.append("|---|---:|---:|---:|---:|---:|---|")
    for c in top_chats:
        lines.append(
            f"| {c['chat_name'].replace('|', '/')} | {c['messages']:,} | {c['outbound_pct']} | "
            f"{c['avg_sentiment']} | {c['median_my_response_minutes']} | "
            f"{c['median_their_response_minutes']} | {c['dominant_theme']} |"
        )
    lines.append("")
    lines.append("## Most Positive Recurring Chats")
    lines.append("")
    for c in most_positive:
        lines.append(f"- `{c['chat_name']}`: {c['avg_sentiment']} across {c['messages']:,} messages")
    lines.append("")
    lines.append("## Most Negative Recurring Chats")
    lines.append("")
    for c in most_negative:
        lines.append(f"- `{c['chat_name']}`: {c['avg_sentiment']} across {c['messages']:,} messages")
    lines.append("")
    lines.append("## Most One-Sided Recurring Chats")
    lines.append("")
    for c in asymmetry:
        direction = "outbound" if c["outbound_pct"] > 50 else "inbound"
        lines.append(f"- `{c['chat_name']}`: {c['outbound_pct']}% outbound, {direction}-heavy, {c['messages']:,} messages")
    lines.append("")
    lines.append("## Top Terms And Phrases")
    lines.append("")
    for item in summary["top_terms"][:40]:
        lines.append(f"- {item['text']} ({item['count']})")
    lines.append("")
    lines.append("## Method Notes")
    lines.append("")
    lines.append("- Sentiment is local lexicon-based analysis, not a cloud model. It is useful for aggregate directional patterns, not perfect emotional truth.")
    lines.append("- Messages were read read-only from `chat.db`; the script did not send, modify, or delete messages.")
    lines.append("- Contact names are whatever Messages stores in `chat.db`; some group chats may appear by identifier if no display name is stored.")
    return "\n".join(lines) + "\n"


def main():
    stamp = dt.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    out_dir = DESKTOP / f"messages-analysis-{stamp}"
    out_dir.mkdir(parents=True, exist_ok=False)

    rows = read_rows()
    summary, chat_summaries = analyze(rows)

    message_fields = [
        "message_id", "message_guid", "chat_id", "chat_name", "chat_identifier", "contact",
        "direction", "service", "datetime", "date", "hour", "weekday", "is_from_me",
        "is_read", "is_sent", "is_delivered", "has_attachments", "is_system_message",
        "associated_message_type", "sentiment_score", "sentiment_label", "word_count",
        "char_count", "text",
    ]
    chat_fields = [
        "chat_id", "chat_name", "chat_identifier", "messages", "text_messages", "outbound",
        "inbound", "outbound_pct", "avg_sentiment", "avg_my_sentiment", "avg_their_sentiment",
        "positive_pct", "negative_pct", "median_my_response_minutes",
        "median_their_response_minutes", "first_message", "last_message", "top_terms",
        "dominant_theme",
    ]
    bucket_fields = ["bucket", "messages", "outbound", "inbound", "avg_sentiment", "positive_pct", "negative_pct"]

    write_csv(out_dir / "messages_with_sentiment.csv", rows, message_fields)
    write_csv(out_dir / "chat_sentiment_summary.csv", chat_summaries, chat_fields)
    write_csv(out_dir / "monthly_sentiment.csv", summary["monthly"], bucket_fields)
    write_csv(out_dir / "daily_sentiment.csv", summary["daily"], bucket_fields)
    write_csv(out_dir / "hourly_sentiment.csv", summary["hourly"], bucket_fields)
    write_csv(out_dir / "weekday_sentiment.csv", summary["weekday"], bucket_fields)
    write_csv(out_dir / "service_sentiment.csv", summary["service"], bucket_fields)
    write_csv(out_dir / "response_time_samples.csv", summary["response_samples"], [
        "chat_id", "chat_name", "responder", "minutes", "previous_datetime", "response_datetime",
    ])
    with (out_dir / "analysis_summary.json").open("w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    (out_dir / "pattern_report.md").write_text(markdown_report(summary, chat_summaries), encoding="utf-8")

    manifest = {
        "output_dir": str(out_dir),
        "files": sorted(p.name for p in out_dir.iterdir()),
        "summary": {
            "messages": summary["total_message_rows"],
            "messages_with_text": summary["messages_with_text"],
            "unique_chats": summary["unique_chats"],
            "date_range": summary["date_range"],
            "avg_sentiment": summary["sentiment"]["avg_score"],
        },
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
