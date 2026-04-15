#!/bin/bash
# Serve the start page on localhost so localStorage works in Chromium.
# Usage: ./serve.sh [port]
#   Then open http://localhost:8484 in Chromium.
PORT="${1:-1234}"
DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Serving $DIR on http://localhost:$PORT"
exec python3 -m http.server "$PORT" -d "$DIR" -b 127.0.0.1
