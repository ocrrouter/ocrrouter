#!/usr/bin/env bash
# OCR a local file or URL with OCRRouter. Prints Markdown (or JSON with --format json) to stdout.
#   ocr.sh <file-or-url> [--model auto|jina/jina-ocr|...] [--format markdown|json|text] [--pages 1-3]
#   ocr.sh --models
# Needs OCRROUTER_API_KEY (create one at https://ocrrouter.ai/keys). Requires curl and python3.
set -euo pipefail
BASE="${OCRROUTER_BASE_URL:-https://api.ocrrouter.ai}"

if [[ "${1:-}" == "--models" ]]; then
  curl -fsS "$BASE/v1/models" | python3 -c 'import sys,json
for m in json.load(sys.stdin)["data"]:
    if m.get("available"): print(m["id"], "free" if m["credits_per_page"]==0 else str(m["credits_per_page"])+" credits/page", sep="\t")'
  exit 0
fi

[[ $# -ge 1 && "$1" != -* ]] || { echo "usage: ocr.sh <file-or-url> [--model ID] [--format markdown|json|text] [--pages RANGE]" >&2; exit 2; }
: "${OCRROUTER_API_KEY:?Set OCRROUTER_API_KEY (get a key at https://ocrrouter.ai/keys)}"
SRC="$1"; shift
MODEL=auto FORMAT=markdown PAGES=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --pages) PAGES="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

BODY=$(mktemp); OUT=$(mktemp); trap 'rm -f "$BODY" "$OUT"' EXIT
SRC="$SRC" MODEL="$MODEL" FORMAT="$FORMAT" PAGES="$PAGES" python3 - >"$BODY" <<'PY'
import base64, json, os, re
src = os.environ["SRC"]
b = {"model": os.environ["MODEL"], "format": os.environ["FORMAT"]}
if os.environ["PAGES"]: b["pages"] = os.environ["PAGES"]
if re.match(r"https?://", src): b["file_url"] = src
else:
    b["file_base64"] = base64.b64encode(open(src, "rb").read()).decode()
    b["filename"] = os.path.basename(src)
print(json.dumps(b))
PY

CODE=$(curl -sS -o "$OUT" -w '%{http_code}' "$BASE/v1/ocr" \
  -H "Authorization: Bearer $OCRROUTER_API_KEY" -H "Content-Type: application/json" --data-binary @"$BODY")

FORMAT="$FORMAT" CODE="$CODE" python3 - "$OUT" <<'PY'
import json, os, sys
raw = open(sys.argv[1]).read()
try: j = json.loads(raw)
except ValueError: sys.exit(f"ocr.sh: HTTP {os.environ['CODE']}: {raw[:300]}")
if not os.environ["CODE"].startswith("2"):
    sys.exit(f"ocr.sh: HTTP {os.environ['CODE']}: {(j.get('error') or {}).get('message', raw[:300])}")
fmt = os.environ["FORMAT"]
if fmt == "json": print(json.dumps(j, indent=2))
else: print(j.get("markdown") or j.get("text") or j.get("output") or json.dumps(j, indent=2))
u = j.get("usage", {})
print(f"ocrrouter: {j.get('model')}, {u.get('pages')} page(s), {u.get('credits')} credits", file=sys.stderr)
PY
