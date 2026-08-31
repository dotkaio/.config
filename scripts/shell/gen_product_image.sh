#!/usr/bin/env bash

CSV="$1"
BASE_URL="https://ljwjtayjfkshgwglhnqr.supabase.co/storage/v1/object/public/bucket/base.jpg"
OUT="Vials"
mkdir -p "$OUT"

command -v jq >/dev/null || { echo "jq required"; exit 1; }

# skip header
tail -n +2 "$CSV" | while IFS=, read -r slug dose; do
    slug="$(printf "%s" "${slug:-}" | tr -d '\r' | xargs)"
    dose="$(printf "%s" "${dose:-}" | tr -d '\r' | xargs)"
    [[ -z "$slug" || -z "$dose" ]] && continue

    # if file exist inside OUT, skip
    name="$(echo "$slug" | tr '[:lower:]' '[:upper:]' | xargs)"
    out_file="${OUT}/${name}_${dose}.jpg"
    [[ -f "$out_file" ]] && { echo "skipping existing: $out_file"; continue; }

    prompt="Replace 'CJC-1295' for '${name}' in (black) and '5' for '${dose}' in (red)."

    success=false
    for attempt in 1 2; do
        resp="$(curl -sS -X POST https://api.x.ai/v1/images/edits \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $XAI_API_KEY" \
            -d '{
          "model": "grok-imagine-image",
          "prompt": "'"$prompt"'",
          "image": { "url": "'"$BASE_URL"'", "type": "image_url" }
        }')"

        err="$(echo "$resp" | jq -r '.error // empty')"
        if [[ -n "$err" ]]; then
            echo "API error for $slug,$dose (attempt $attempt): $err" >&2
            if [[ $attempt -lt 2 ]]; then
                echo "Retrying in 1 second..." >&2
                sleep 1
                continue
            fi
            echo "$resp" | jq . >&2
            exit 1
        fi

        b64="$(echo "$resp" | jq -r '.data[0].b64_json // empty')"
        url="$(echo "$resp" | jq -r '.data[0].url // empty')"

        if [[ -n "$b64" ]]; then
            echo "$b64" | base64 --decode > "$out_file"
            success=true
            break
            elif [[ -n "$url" ]]; then
            curl -sS "$url" -o "$out_file"
            success=true
            break
        else
            echo "No image returned for $slug,$dose (attempt $attempt)" >&2
            if [[ $attempt -lt 2 ]]; then
                echo "Retrying in 1 second..." >&2
                sleep 1
                continue
            fi
            echo "$resp" | jq . >&2
            exit 1
        fi
    done

    echo "saved: $out_file"
done
