# Installing the OCRRouter MCP server

OCRRouter is a hosted remote MCP server. Nothing needs to be cloned, built or run locally.

1. Ask the user for an OCRRouter API key. They can create a free one at https://ocrrouter.ai/keys (Jina OCR and DeepSeek-OCR are free, 50,000 pages a month).
2. Add this server to the MCP settings file (for Cline: `cline_mcp_settings.json`), replacing `YOUR_API_KEY`:

```json
{
  "mcpServers": {
    "ocrrouter": {
      "type": "streamableHttp",
      "url": "https://api.ocrrouter.ai/v1/mcp",
      "headers": { "Authorization": "Bearer YOUR_API_KEY" },
      "disabled": false
    }
  }
}
```

3. Check the connection by calling the `list_models` tool. It works even before a key is set.
4. Call the `ocr` tool with `file_url` (a public PDF or image URL) or `file_base64` plus `filename`. Optional: `model` (default `auto`; `jina/jina-ocr` and `deepseek/deepseek-ocr` are free), `format` (`markdown`, `json` or `text`), `pages` (for example `1-3`).

If the client cannot send headers, use `https://api.ocrrouter.ai/v1/mcp?key=YOUR_API_KEY` instead.
