#!/usr/bin/env python3

import base64
import json
import os
import re
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import subprocess
import glob
from datetime import datetime
from html import escape
from typing import Any, Dict, Tuple


def _json_loads(s: str):
    try:
        return json.loads(s)
    except Exception:
        return None


def _slug(s: str) -> str:
    s = (s or "person").strip()
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"[^A-Za-z0-9 _.-]", "", s)
    s = s.replace(" ", "_")
    return s[:80] if s else "person"


def _norm_phone(s: str):
    if not s:
        return None
    s = str(s)
    # Keep leading + if present.
    leading_plus = s.strip().startswith("+")
    digits = re.sub(r"\D", "", s)
    if not digits:
        return None
    return ("+" if leading_plus else "") + digits


def _digits_only(s: str) -> str:
    if s is None:
        return ""
    return re.sub(r"\D", "", str(s))


def _normalize_us_phone_digits(s: str) -> str:
    digits = _digits_only(s)
    # US numbers: strip leading country code 1 when provided.
    if len(digits) == 11 and digits.startswith("1"):
        return digits[1:]
    if len(digits) == 10:
        return digits
    return ""


def _normalize_email(s: str) -> str:
    s = (s or "").strip().lower()
    return s if ("@" in s and "." in s) else ""


def _extract_email_addresses(person_obj: dict) -> list[str]:
    out: list[str] = []
    email_entries = person_obj.get("emailAddresses") or person_obj.get("emails")
    if isinstance(email_entries, list):
        for it in email_entries:
            if isinstance(it, dict):
                e = it.get("emailAddress") or it.get("email") or it.get("value")
                if isinstance(e, str) and e.strip():
                    out.append(e.strip())
            elif isinstance(it, str) and it.strip():
                out.append(it.strip())
    return list(dict.fromkeys(out))


def _extract_phone_entries(person_obj: dict) -> list[dict]:
    entries = person_obj.get("phoneNumbers")
    if isinstance(entries, list):
        return [it for it in entries if isinstance(it, dict)]
    return []


def _vercel_chat_completion(messages: list[dict], model: str) -> str:
    api_key = os.environ.get("AI_GATEWAY_API_KEY")
    if not api_key:
        return ""

    url = os.environ.get("AI_GATEWAY_CHAT_URL") or "https://ai-gateway.vercel.sh/v1/chat/completions"
    payload = {
        "model": model,
        "messages": messages,
        "temperature": 0.2,
        "max_tokens": int(os.environ.get("AI_GATEWAY_MAX_TOKENS", "280")),
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except Exception:
        return ""

    parsed = _json_loads(raw)
    content = (
        parsed.get("choices", [{}])[0].get("message", {}).get("content", "")
        if isinstance(parsed, dict)
        else ""
    )
    return content.strip() if isinstance(content, str) else ""


def _generate_person_summary(*, query: str, name: str, phones: list[str], emails: list[str], photo_url: str, social_urls: list[str]) -> str:
    # Keep it short and safe: no guessing, only summarize what we have.
    socials_text = "\n".join(f"- {u}" for u in social_urls[:8]) if social_urls else "(none found)"
    phones_text = ", ".join(phones[:3]) if phones else "(none)"
    emails_text = ", ".join(emails[:3]) if emails else "(none)"

    system = (
        "You write a short, factual contact card summary. "
        "Do not invent. If info is missing, say it's not available. "
        "Output 3-5 concise bullet points, total <= 500 characters, no quotes."
    )
    user = (
        f"Person searched: {query}\n"
        f"Name: {name}\n"
        f"Phones (verified from data): {phones_text}\n"
        f"Emails: {emails_text}\n"
        f"Photo URL: {photo_url or '(none)'}\n"
        f"Social links found:\n{socials_text}\n"
    )
    return _vercel_chat_completion(
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        model=os.environ.get("AI_GATEWAY_PERSON_MODEL") or "openai/gpt-5.4-nano",
    )


def _run_blackbird_socials(email: str) -> list[str]:
    email = _normalize_email(email)
    if not email:
        return []

    repo_dir = "/Users/kaioferraz/Developer/blackbird"
    results_dir = os.path.join(repo_dir, "results")
    try:
        proc = subprocess.run(
            [
                "python3",
                os.path.join(repo_dir, "blackbird.py"),
                "--email",
                email,
                "--filter",
                "cat=social",
                "--json",
                "--no-update",
                "--timeout",
                os.environ.get("BLACKBIRD_TIMEOUT_SECONDS", "20"),
                "--max-concurrent-requests",
                os.environ.get("BLACKBIRD_MAX_CONCURRENT_REQUESTS", "10"),
            ],
            cwd=repo_dir,
            capture_output=True,
            text=True,
            timeout=int(os.environ.get("BLACKBIRD_PROCESS_TIMEOUT_SECONDS", "120")),
        )
        if proc.returncode != 0:
            return []
    except Exception:
        return []

    # Find newest json result file for this email.
    try:
        pattern = os.path.join(results_dir, f"{email}_*_blackbird.json")
        files = glob.glob(pattern)
        if not files:
            return []
        latest = max(files, key=lambda p: os.path.getmtime(p))
        with open(latest, "r", encoding="utf-8") as f:
            data = json.load(f)
        urls: list[str] = []
        if isinstance(data, list):
            for it in data:
                if isinstance(it, dict):
                    u = it.get("url") or it.get("uri")
                    if isinstance(u, str) and u.startswith("http"):
                        urls.append(u)
        # Dedupe
        return list(dict.fromkeys(urls))[:10]
    except Exception:
        return []


def _pick_first(obj, keys, default=""):
    for k in keys:
        v = obj.get(k)
        if isinstance(v, str) and v.strip():
            return v.strip()
        if isinstance(v, (int, float)):
            return str(v)
    return default


def _parse_person_or_contact_query(query: str) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    """Return (body, extra) for Enformion Person Search.

    This keeps the CLI `lookup()` behavior generic: if the query looks like an email or phone,
    we set the corresponding field; otherwise we treat it as First/Last name.
    """

    q = (query or "").strip()
    body: Dict[str, Any] = {}

    # Email
    if "@" in q and "." in q:
        body["Email"] = q
        return body, {}

    # Phone: Enformion expects US 10-digit number (without leading country code).
    digits = re.sub(r"\D", "", q)
    if digits and len(digits) >= 10:
        if len(digits) == 11 and digits.startswith("1"):
            digits = digits[1:]
        if len(digits) == 10:
            body["Phone"] = digits
        else:
            # Keep best-effort original query if it doesn't look like US.
            body["Phone"] = q
        return body, {}

    # Name: First Middle Last-ish
    parts = [p for p in re.split(r"\s+", q) if p]
    if not parts:
        return body, {}

    if len(parts) == 1:
        body["LastName"] = parts[0]
    else:
        body["FirstName"] = parts[0]
        body["LastName"] = parts[-1]
        if len(parts) > 2:
            body["MiddleName"] = " ".join(parts[1:-1])
    return body, {}


def _pick_biography(obj: dict) -> str:
    for k in [
        "biography",
        "bio",
        "biography_text",
        "description",
        "summary",
        "about",
        "life",
    ]:
        v = obj.get(k)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return ""


def _pick_picture_url(obj: dict) -> str:
    for k in [
        "profile_picture_url",
        "picture_url",
        "avatar_url",
        "image_url",
        "photo_url",
        "photo",
        "image",
        "thumbnail",
    ]:
        v = obj.get(k)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return ""


def _pick_phones(obj: dict):
    phone_candidates = [
        "phones",
        "phone_numbers",
        "phoneNumbers",
        "contact_numbers",
        "numbers",
        "telephones",
    ]
    for k in phone_candidates:
        v = obj.get(k)
        if isinstance(v, list):
            out = []
            for it in v:
                if isinstance(it, str):
                    out.append(it)
                elif isinstance(it, dict):
                    for kk in ["number", "value", "phone", "phoneNumber"]:
                        if isinstance(it.get(kk), str):
                            out.append(it[kk])
                            break
            return [p for p in (_norm_phone(x) for x in out) if p]
        if isinstance(v, str) and v.strip():
            # Try to extract multiple numbers from a string blob.
            nums = re.findall(r"\+?\d[\d\s().-]{6,}\d", v)
            return [p for p in (_norm_phone(x) for x in nums) if p]
    return []


def _groq_analysis(biography: str, name: str) -> str:
    groq_key = os.environ.get("GROQ_API_KEY")
    if not groq_key or not biography.strip():
        return ""

    # OpenAI-compatible chat endpoint on Groq.
    url = "https://api.groq.com/openai/v1/chat/completions"
    prompt_bio = biography.strip()
    if len(prompt_bio) > 8000:
        prompt_bio = prompt_bio[:8000] + "\n..."

    body = {
        "model": os.environ.get("GROQ_ANALYSIS_MODEL", "openai/gpt-oss-120b"),
        "temperature": 0.7,
        "max_completion_tokens": int(os.environ.get("GROQ_ANALYSIS_MAX_TOKENS", "400")),
        "top_p": 1,
        "stream": False,
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are writing a short, actionable AI analysis of a person's biography. "
                    "Return 3-6 bullet points. Be factual, avoid inventing details. "
                    "Keep total output under ~900 characters."
                ),
            },
            {
                "role": "user",
                "content": f"Name: {name}\n\nBiography:\n{prompt_bio}",
            },
        ],
    }

    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {groq_key}",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        try:
            raw = e.read().decode("utf-8", errors="replace")
        except Exception:
            raw = str(e)
        return f"(AI analysis unavailable: HTTP {e.code})"
    except Exception:
        return "(AI analysis unavailable)"

    parsed = _json_loads(raw) or {}
    content = (
        parsed.get("choices", [{}])[0]
        .get("message", {})
        .get("content", "")
    )
    return content.strip()


def _download_as_data_uri(url: str) -> str:
    if not url:
        return ""
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            data = resp.read()
            ctype = resp.headers.get("Content-Type") or "image/jpeg"
    except Exception:
        return ""

    # Keep mime-type only.
    ctype = ctype.split(";", 1)[0].strip() or "image/jpeg"
    b64 = base64.b64encode(data).decode("ascii")
    return f"data:{ctype};base64,{b64}"


def main():
    if len(sys.argv) < 2:
        print("Usage: enformion_lookup_to_html.py <query>", file=sys.stderr)
        return 2

    query = " ".join(sys.argv[1:]).strip()
    if not query:
        print("Empty query", file=sys.stderr)
        return 2

    # Person Search: demo page uses devapi endpoint.
    lookup_url = os.environ.get("ENFORMION_LOOKUP_URL") or "https://devapi.enformion.com/personsearch"

    ap_name = os.environ.get("ENFORMION_GALAXY_AP_NAME") or os.environ.get("ENFORMION_KEY_NAME")
    ap_password = os.environ.get("ENFORMION_GALAXY_AP_PASSWORD") or os.environ.get("ENFORMION_KEY_PASSWORD")
    if not ap_name or not ap_password:
        print(
            "Missing Enformion access profile headers. Set ENFORMION_KEY_NAME/ENFORMION_KEY_PASSWORD (or ENFORMION_GALAXY_AP_NAME/ENFORMION_GALAXY_AP_PASSWORD).",
            file=sys.stderr,
        )
        return 2

    galaxy_search_type = os.environ.get("ENFORMION_GALAXY_SEARCH_TYPE") or "Person"

    timeout = int(os.environ.get("ENFORMION_TIMEOUT_SECONDS", "40"))

    # Build Person Search-like body from `query`.
    body, _ = _parse_person_or_contact_query(query)
    # Defaults: expand addresses and phone numbers when present.
    body.setdefault("Page", int(os.environ.get("ENFORMION_PAGE", "1")))
    body.setdefault("ResultsPerPage", int(os.environ.get("ENFORMION_RESULTS_PER_PAGE", "10")))

    includes = os.environ.get("ENFORMION_INCLUDES")
    if includes:
        body["Includes"] = [x.strip() for x in includes.split(",") if x.strip()]
    else:
        body.setdefault("Includes", ["Addresses", "PhoneNumbers"])

    filter_options = os.environ.get("ENFORMION_FILTER_OPTIONS")
    if filter_options:
        body["FilterOptions"] = [x.strip() for x in filter_options.split(",") if x.strip()]
    else:
        body.setdefault("FilterOptions", ["IncludeLowQualityAddresses"])

    data = json.dumps(body).encode("utf-8")

    headers = {
        "Content-Type": "application/json",
        "galaxy-ap-name": ap_name,
        "galaxy-ap-password": ap_password.strip(),
        "galaxy-search-type": galaxy_search_type,
    }

    req = urllib.request.Request(lookup_url, data=data, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            status = resp.status
            resp_headers = dict(resp.headers)
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace") if e.fp else ""
        print(f"Enformion API HTTP error: {e.code}", file=sys.stderr)
        print(raw[:2000], file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Enformion API request failed: {e}", file=sys.stderr)
        return 1

    parsed = _json_loads(raw)
    if not isinstance(parsed, dict):
        print("Enformion API did not return a JSON object.", file=sys.stderr)
        return 1

    email_input = _normalize_email(query)
    phone_input_digits = _normalize_us_phone_digits(query)

    # Person Search typically returns a list under `persons`.
    persons_list: list[dict] = []
    for list_key in ["persons", "people", "results", "People", "Results"]:
        v = parsed.get(list_key)
        if isinstance(v, list):
            persons_list = [it for it in v if isinstance(it, dict)]
            if persons_list:
                break

    person_obj: Dict[str, Any]
    if persons_list:
        person_obj = {}

        if email_input:
            for p in persons_list:
                p_emails = [e.lower() for e in _extract_email_addresses(p)]
                if email_input in p_emails:
                    person_obj = p
                    break

        if not person_obj and phone_input_digits:
            for p in persons_list:
                for ph in _extract_phone_entries(p):
                    pn = ph.get("phoneNumber") or ph.get("phone")
                    if _normalize_us_phone_digits(str(pn or "")) == phone_input_digits:
                        person_obj = p
                        break
                if person_obj:
                    break

        if not person_obj:
            person_obj = persons_list[0]
    else:
        person_obj = parsed

    name = _pick_first(
        person_obj,
        ["name", "full_name", "person_name", "displayName", "title", "first_name"],
        default="Person",
    )

    # `name` may be an object: {firstName, lastName, ...}
    if name == "Person" and isinstance(person_obj.get("name"), dict):
        n = person_obj.get("name")
        first = n.get("firstName") or n.get("first_name")
        last = n.get("lastName") or n.get("last_name")
        if isinstance(first, str) and first.strip() and isinstance(last, str) and last.strip():
            name = f"{first.strip()} {last.strip()}"
        elif isinstance(first, str) and first.strip():
            name = first.strip()
        elif isinstance(last, str) and last.strip():
            name = last.strip()
    biography = _pick_biography(person_obj)
    photo_url = _pick_picture_url(person_obj)

    # Phones: only keep up to 3 connected numbers, preferring the queried one.
    phone_entries = _extract_phone_entries(person_obj)
    selected_entries: list[dict] = []
    seen_digits: set[str] = set()

    def entry_digits(entry: dict) -> str:
        pn = entry.get("phoneNumber") or entry.get("phone")
        return _normalize_us_phone_digits(str(pn or "")) or _digits_only(str(pn or ""))

    if phone_input_digits:
        exact = [e for e in phone_entries if entry_digits(e) == phone_input_digits]
        connected = [e for e in phone_entries if bool(e.get("isConnected"))]
        for e in exact:
            d = entry_digits(e)
            if d and d not in seen_digits:
                selected_entries.append(e)
                seen_digits.add(d)
        for e in connected:
            if len(selected_entries) >= 3:
                break
            d = entry_digits(e)
            if d and d not in seen_digits:
                selected_entries.append(e)
                seen_digits.add(d)
    else:
        connected = [e for e in phone_entries if bool(e.get("isConnected"))]
        ordered = connected if connected else phone_entries
        for e in ordered:
            if len(selected_entries) >= 3:
                break
            d = entry_digits(e)
            if d and d not in seen_digits:
                selected_entries.append(e)
                seen_digits.add(d)

    phones = [entry_digits(e) for e in selected_entries if entry_digits(e)]
    if not phones:
        phones = _pick_phones(person_obj)[:3]

    emails = _extract_email_addresses(person_obj)
    if email_input:
        emails = [e for e in emails if e.lower() == email_input] or emails
    emails = emails[:3]

    social_urls: list[str] = []
    social_search_email = email_input or (emails[0] if emails else "")
    if social_search_email:
        social_urls = _run_blackbird_socials(social_search_email)

    ai_analysis = _generate_person_summary(
        query=query,
        name=name,
        phones=phones,
        emails=emails,
        photo_url=photo_url,
        social_urls=social_urls,
    )

    # Download photo as data URI for standalone HTML.
    photo_data_uri = _download_as_data_uri(photo_url)

    safe = _slug(name)
    desktop = os.path.expanduser("~/Desktop")
    html_path = os.path.join(desktop, f"{safe}.html")
    json_path = os.path.join(desktop, f"{safe}.enformion.json")

    phones_html = "".join(f"<li>{escape(p)}</li>" for p in phones) or "<li>(none)</li>"

    emails_html = "".join(f"<li>{escape(e)}</li>" for e in emails) or "<li>(none)</li>"

    social_html = (
        "".join(
            f"<li><a href=\"{escape(u)}\" target=\"_blank\" rel=\"noreferrer\">{escape(u)}</a></li>"
            for u in social_urls[:8]
        )
        or "<li>(none)</li>"
    )

    photo_tag = ""
    if photo_data_uri:
        photo_tag = f'<img class="avatar" src="{photo_data_uri}" alt="Profile picture" />'
    elif photo_url:
        photo_tag = f'<img class="avatar" src="{escape(photo_url)}" alt="Profile picture" />'
    else:
        photo_tag = '<div class="avatar placeholder">No photo</div>'

    html = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{escape(name)}</title>
  <style>
    :root {{ color-scheme: light; }}
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 32px; background: #fff; color: #111; }}
    .card {{ max-width: 760px; margin: 0 auto; }}
    .top {{ display: flex; gap: 18px; align-items: center; }}
    .avatar {{ width: 110px; height: 110px; border-radius: 18px; object-fit: cover; border: 1px solid #eee; background: #f6f7f9; }}
    .avatar.placeholder {{ display:flex; align-items:center; justify-content:center; font-size: 12px; color: #666; }}
    h1 {{ margin: 0; font-size: 26px; }}
    .sub {{ margin-top: 6px; color: #444; font-size: 13px; }}
    .section {{ margin-top: 22px; padding-top: 12px; border-top: 1px solid #eee; }}
    .section h2 {{ margin: 0 0 10px; font-size: 16px; }}
    ul {{ margin: 0; padding-left: 20px; }}
    .bio {{ white-space: pre-wrap; line-height: 1.55; }}
    .analysis ul {{ padding-left: 18px; }}
    .muted {{ color: #666; font-size: 12px; }}
    @media (max-width: 520px) {{ .top {{ flex-direction: column; align-items: flex-start; }} .avatar {{ width: 96px; height: 96px; }} }}
  </style>
</head>
<body>
  <div class="card">
    <div class="top">
      {photo_tag}
      <div>
        <h1>{escape(name)}</h1>
        <div class="sub">Generated from Enformion lookup</div>
      </div>
    </div>

    <div class="section">
      <h2>Contact Numbers</h2>
      <ul>
        {phones_html}
      </ul>
    </div>

    <div class="section">
      <h2>Emails</h2>
      <ul>
        {emails_html}
      </ul>
    </div>

    <div class="section">
      <h2>Biography</h2>
      <div class="bio">{escape(biography) if biography else '<span class="muted">(none)</span>'}</div>
    </div>

    <div class="section analysis">
      <h2>Summary</h2>
      <div class="bio">{escape(ai_analysis) if ai_analysis else '<span class="muted">(AI summary unavailable)</span>'}</div>
    </div>

    <div class="section">
      <h2>Social Links</h2>
      <ul>
        {social_html}
      </ul>
    </div>
  </div>
</body>
</html>"""

    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(
            {
                "query": query,
                "name": name,
                "biography": biography,
                "photo_url": photo_url,
                "phones": phones,
                "ai_analysis": ai_analysis,
                "emails": emails,
                "social_urls": social_urls,
                "enformion_raw": parsed,
                "status": status if "status" in locals() else None,
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    print(f"HTML_PATH={html_path}")
    print(f"JSON_PATH={json_path}")
    print(f"NAME={name}")
    print("PHONES=" + "|".join(phones))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
