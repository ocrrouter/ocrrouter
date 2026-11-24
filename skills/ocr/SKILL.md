---
name: ocr
description: Extract text from a PDF or image (local file or URL) as Markdown or JSON using the OCRRouter API. Use when the user asks to OCR, read, transcribe or extract text or tables from a scanned PDF, photo, screenshot, receipt or invoice.
---

# OCR with OCRRouter

Run `scripts/ocr.sh` to turn a PDF or image into Markdown. It calls `POST https://api.ocrrouter.ai/v1/ocr`.

## Setup

The script needs `OCRROUTER_API_KEY` in the environment. If it is missing, ask the user to create a key at https://ocrrouter.ai/keys. Never print the key.

## Usage

```bash
scripts/ocr.sh path/to/scan.pdf                        # Markdown to stdout, model auto
scripts/ocr.sh https://example.com/invoice.png         # public URL
scripts/ocr.sh scan.pdf --model jina/jina-ocr          # free model
scripts/ocr.sh scan.pdf --format json --pages 1-3      # typed blocks per page
scripts/ocr.sh --models                                # available models and prices
```

- Supported inputs: PDF, PNG, JPG, WebP, GIF, HEIC, TIFF, BMP and Office files (DOCX, PPTX, XLSX, ODT). Local files are sent as base64, up to 20 MB.
- `--model`: `auto` (default) picks a model per document. `jina/jina-ocr` and `deepseek/deepseek-ocr` cost 0 credits, up to 50,000 pages a month per account.
- `--format`: `markdown` (default), `json` or `text`. Markdown keeps tables as tables and separates pages with `<!-- page:N -->`.
- A usage line (model, pages, credits) goes to stderr; the document goes to stdout.

## Errors

- `401`: key missing or revoked.
- `402`: not enough credits. Retry with a free model or ask the user to top up.
- `413`: file too large for the model. Try `--pages` or another model.
- `429`: rate limited. Wait and retry.
