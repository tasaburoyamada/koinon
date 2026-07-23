# Koinon API 規格仕様書

## 1. 概要
本仕様書は、**Koinon Omni-Server** が外部クライアント、AI エージェント、および Web ブラウザに対して提供する通信インターフェース規格（OpenAI 互換 REST API ＆ MCP JSON-RPC 2.0 ＆ 静的Web）を物理レベルで定義する。

---

## 2. REST API 仕様 (OpenAI Compatible)

### 2.1. 利用可能モデル一覧取得 (`GET /v1/models`)

- **リクエスト**:
  ```http
  GET /v1/models HTTP/1.1
  Host: localhost:8080
  Accept: application/json
  ```

- **レスポンス (200 OK)**:
  ```json
  {
    "object": "list",
    "data": [
      {
        "id": "koinon-omni-gemma",
        "object": "model",
        "created": 1700000000,
        "owned_by": "koinon"
      },
      {
        "id": "gemini-2.0-flash-exp",
        "object": "model",
        "created": 1700000000,
        "owned_by": "koinon"
      }
    ]
  }
  ```

---

### 2.2. Chat Completion 生成 (`POST /v1/chat/completions`)

- **リクエスト**:
  ```http
  POST /v1/chat/completions HTTP/1.1
  Host: localhost:8080
  Content-Type: application/json

  {
    "model": "gemini-2.0-flash-exp",
    "messages": [
      {
        "role": "user",
        "content": "Hello, Koinon! Please perform a RAG search."
      }
    ],
    "temperature": 0.7,
    "max_tokens": 1024
  }
  ```

- **レスポンス (200 OK)**:
  ```json
  {
    "id": "chatcmpl-koinon-12345",
    "object": "chat.completion",
    "created": 1700000000,
    "model": "gemini-2.0-flash-exp",
    "choices": [
      {
        "index": 0,
        "message": {
          "role": "assistant",
          "content": "[Koinon Omni-Server] Processed prompt with model 'gemini-2.0-flash-exp'. Received 1 messages."
        },
        "finish_reason": "stop"
      }
    ],
    "usage": {
      "prompt_tokens": 12,
      "completion_tokens": 24,
      "total_tokens": 36
    }
  }
  ```

- **エラーレスポンス (400 Bad Request)**:
  ```json
  {
    "error": "Invalid ChatCompletionRequest: Invalid JSON format"
  }
  ```

---

## 3. MCP (Model Context Protocol) JSON-RPC 仕様

Koinon は Stdio および SSE 経由で MCP 規格（JSON-RPC 2.0）メッセージを受け付ける。

### 3.1. サーバー初期化 (`initialize`)
- **Request**:
  ```json
  {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2.0",
      "capabilities": {}
    }
  }
  ```
- **Response**:
  ```json
  {
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
      "protocolVersion": "2.0",
      "serverInfo": {
        "name": "Koinon Omni-Server",
        "version": "0.1.0-alpha"
      }
    }
  }
  ```

---

## 4. Web UI 静的ファイルサーブ仕様

| URI パス | Content-Type | 提供ファイル |
| :--- | :--- | :--- |
| `/` または `/index.html` | `text/html` | [`web/index.html`](file:///home/pc241139/sandbox/koinon/web/index.html) |
| `/style.css` | `text/css` | [`web/style.css`](file:///home/pc241139/sandbox/koinon/web/style.css) |
| `/app.js` または `/app.ts` | `application/javascript` | [`web/app.js`](file:///home/pc241139/sandbox/koinon/web/app.js) |
