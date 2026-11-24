# OCRRouter

[![OCRRouter MCP connector](https://glama.ai/mcp/connectors/ai.ocrrouter/ocrrouter/badges/score.svg)](https://glama.ai/mcp/connectors/ai.ocrrouter/ocrrouter)

[OCRRouter](https://ocrrouter.ai) is online OCR for images and PDFs, with an API included. One endpoint routes each document across OCR models (Mistral OCR, Gemini, GPT, Claude, Textract, Azure Document Intelligence, Google Document AI, PaddleOCR-VL, GLM-OCR, DeepSeek-OCR, Jina OCR and more) and returns Markdown or JSON.

- **Free API**: `jina/jina-ocr` and `deepseek/deepseek-ocr` cost 0 credits, up to 50,000 pages a month per account.
- **Routing**: `model: "auto"` picks a model per document; `route` chooses `quality`, `cheapest` or `fastest`; `fallbacks` keeps working through outages and you pay only for the model that answered.
- **Benchmark**: 13 OCR models compared on the same documents at https://ocrrouter.ai/benchmark.

This repo holds the remote MCP server config, an agent skill and REST API examples. Get an API key at https://ocrrouter.ai/keys.

## Remote MCP server

| | |
|---|---|
| URL | `https://api.ocrrouter.ai/v1/mcp` |
| Transport | Streamable HTTP |
| Auth | `Authorization: Bearer YOUR_API_KEY`, or `?key=YOUR_API_KEY` for clients that cannot set headers |
| Tools | `ocr` (PDF or image URL or base64 to Markdown, JSON or text), `list_models` (models, credits per page, availability) |

`initialize`, `tools/list` and `list_models` work without a key; `ocr` needs one. Registry name: `ai.ocrrouter/ocrrouter` (see [`server.json`](server.json)).

### Claude Code

```bash
claude mcp add --transport http ocrrouter https://api.ocrrouter.ai/v1/mcp \
  --header "Authorization: Bearer YOUR_API_KEY"
```

### Cursor

Add to `~/.cursor/mcp.json` (or `.cursor/mcp.json` in a project), same as [`mcp.json`](mcp.json):

```json
{
  "mcpServers": {
    "ocrrouter": {
      "url": "https://api.ocrrouter.ai/v1/mcp",
      "headers": { "Authorization": "Bearer YOUR_API_KEY" }
    }
  }
}
```

### Codex

Add to `~/.codex/config.toml`:

```toml
[mcp_servers.ocrrouter]
url = "https://api.ocrrouter.ai/v1/mcp"
bearer_token_env_var = "OCRROUTER_API_KEY"
```

Then `export OCRROUTER_API_KEY=...` before starting Codex.

### `ocr` tool arguments

| Argument | Description |
|---|---|
| `file_url` | Public http(s) URL of a PDF, PNG, JPG, WebP or GIF |
| `file_base64` | Base64 file contents, instead of `file_url` |
| `filename` | File name with extension, recommended with `file_base64` |
| `format` | `markdown` (default), `json` or `text` |
| `model` | Model ID from `list_models`, or `auto` (default) |
| `pages` | Page range such as `1-5,8`; default all pages |

## Agent skill

[`skills/ocr`](skills/ocr) is an [Agent Skill](https://agentskills.io) that OCRs a local file or URL through the REST API. It reads the key from `OCRROUTER_API_KEY`.

```bash
export OCRROUTER_API_KEY=...
skills/ocr/scripts/ocr.sh scan.pdf --model jina/jina-ocr
skills/ocr/scripts/ocr.sh https://example.com/invoice.png --format json
skills/ocr/scripts/ocr.sh --models
```

Copy `skills/ocr` into your agent's skills folder (for Claude Code: `~/.claude/skills/ocr`).

## REST API quick start

`POST https://api.ocrrouter.ai/v1/ocr` with a JSON body and an `Authorization: Bearer` header.

```bash
# A public URL, model chosen automatically
curl https://api.ocrrouter.ai/v1/ocr \
  -H "Authorization: Bearer $OCRROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "auto",
    "file_url": "https://example.com/invoice.pdf",
    "format": "markdown"
  }'

# A local file with a free model
curl https://api.ocrrouter.ai/v1/ocr \
  -H "Authorization: Bearer $OCRROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"jina/jina-ocr\", \"filename\": \"scan.png\", \"file_base64\": \"$(base64 < scan.png | tr -d '\n')\"}"

# Fallbacks: try the next model if the first one fails
curl https://api.ocrrouter.ai/v1/ocr \
  -H "Authorization: Bearer $OCRROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral/mistral-ocr",
    "fallbacks": ["google/gemini-flash", "tesseract/tesseract"],
    "file_url": "https://example.com/report.pdf"
  }'

# List models and prices (no key needed)
curl https://api.ocrrouter.ai/v1/models
```

Request fields: `model`, `file_url`, `file_base64` (up to 20 MB), `file_id` (from `POST /v1/files` for larger files), `format` (`markdown`, `json`, `text`, `html`, `csv`, `docx`, `xlsx`), `pages`, `fallbacks`, `route`, `filename`. Every response includes `model` and `usage.credits`; failed and empty results are free.

Other endpoints:

- `GET /v1/models`: every model, its price and whether it is available. No key needed.
- `POST /v1/files`: multipart upload with a `file` field; returns a `file_id` that works for 24 hours.
- `GET /v1/requests/:id`: an earlier result; add `?format=` to get it in another format.
- `GET /v1/credits`: your balance and this key's usage.
- `POST /v1/keys/temporary`: a temporary key for agents without an account, one per day.

Full docs: https://ocrrouter.ai/docs. Machine-readable summary: https://ocrrouter.ai/llms.txt.

## License

[MIT](LICENSE)
