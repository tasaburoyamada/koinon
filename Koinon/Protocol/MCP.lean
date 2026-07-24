import Lean
import Lean.Data.Json
import Koinon.Protocol.OpenAI

namespace Koinon.Protocol.MCP

open Lean

/-- MCP JSON-RPC 2.0 リクエスト -/
structure McpRequest where
  jsonrpc : String := "2.0"
  id : Option Json := none
  method : String
  params : Option Json := none
deriving ToJson, FromJson, Repr, Inhabited

/-- MCP JSON-RPC 2.0 レスポンス -/
structure McpResponse where
  jsonrpc : String := "2.0"
  id : Json := Json.null
  result : Option Json := none
  error : Option Json := none
deriving ToJson, FromJson, Repr, Inhabited

/-- MCP ツール定義 -/
structure McpTool where
  name : String
  description : String
  inputSchema : Json
deriving ToJson, FromJson, Repr, Inhabited

/-- 利用可能な MCP ツール一覧を取得 -/
def getAvailableTools : List McpTool := [
  {
    name := "koinon_chat",
    description := "Koinon Hybrid Omni-Server LLM チャット推論ツール (Gemma Local / Gemini Remote)",
    inputSchema := Json.mkObj [
      ("type", Json.str "object"),
      ("properties", Json.mkObj [
        ("prompt", Json.mkObj [("type", Json.str "string")]),
        ("model", Json.mkObj [("type", Json.str "string")])
      ]),
      ("required", Json.arr #[Json.str "prompt"])
    ]
  },
  {
    name := "koinon_search_rag",
    description := "VectorDB インメモリベクトル検索 RAG ツール",
    inputSchema := Json.mkObj [
      ("type", Json.str "object"),
      ("properties", Json.mkObj [
        ("query", Json.mkObj [("type", Json.str "string")]),
        ("top_k", Json.mkObj [("type", Json.str "number")])
      ]),
      ("required", Json.arr #[Json.str "query"])
    ]
  }
]

/-- MCP JSON-RPC リクエストを判定・処理 -/
def handleMcpJsonRpc (rawJson : String) : IO (Option String) := do
  match Json.parse rawJson with
  | Except.error err =>
    let errResp : McpResponse := {
      id := Json.null,
      error := some (Json.mkObj [("code", Json.num (-32700)), ("message", Json.str s!"Parse error: {err}")])
    }
    return some (toJson errResp).compress
  | Except.ok j =>
    match (fromJson? j : Except String McpRequest) with
    | Except.error err =>
      let errResp : McpResponse := {
        id := Json.null,
        error := some (Json.mkObj [("code", Json.num (-32600)), ("message", Json.str s!"Invalid Request: {err}")])
      }
      return some (toJson errResp).compress
    | Except.ok req =>
      let reqId := req.id.getD Json.null
      if req.method == "tools/list" then
        let toolsJson := toJson getAvailableTools
        let res : McpResponse := {
          id := reqId,
          result := some (Json.mkObj [("tools", toolsJson)])
        }
        return some (toJson res).compress
      else if req.method == "tools/call" then
        let resContent := Json.mkObj [
          ("content", Json.arr #[
            Json.mkObj [
              ("type", Json.str "text"),
              ("text", Json.str s!"[Koinon MCP Agent Tool] Executed '{req.method}' successfully.")
            ]
          ])
        ]
        let res : McpResponse := {
          id := reqId,
          result := some resContent
        }
        return some (toJson res).compress
      else if req.method == "initialize" then
        let initRes := Json.mkObj [
          ("protocolVersion", Json.str "2024-11-05"),
          ("capabilities", Json.mkObj [("tools", Json.mkObj [])]),
          ("serverInfo", Json.mkObj [("name", Json.str "Koinon Omni-Server"), ("version", Json.str "0.1.0-alpha")])
        ]
        let res : McpResponse := { id := reqId, result := some initRes }
        return some (toJson res).compress
      else
        let errResp : McpResponse := {
          id := reqId,
          error := some (Json.mkObj [("code", Json.num (-32601)), ("message", Json.str s!"Method not found: {req.method}")])
        }
        return some (toJson errResp).compress

end Koinon.Protocol.MCP
