import Lean
import Lean.Data.Json
import Koinon.Protocol.OpenAI
import Koinon.Protocol.MCP
import Koinon.Engine.HybridRouter
import Lyceum.Memory.VectorDB

namespace Koinon.Server

open Lean
open Koinon.Protocol.OpenAI
open Koinon.Protocol.MCP
open Koinon.Engine
open Lyceum.Memory

structure HttpResponse where
  status : Nat := 200
  contentType : String := "application/json"
  body : String
deriving Repr, Inhabited

/-- REST API & MCP リクエストを処理するメインルーター -/
def handleRoute (method : String) (path : String) (body : String) (db : VectorDB) : IO HttpResponse := do
  -- 1. Web Assets Routes
  if method == "GET" && (path == "/" || path == "/index.html") then
    let content ← IO.FS.readFile "web/index.html"
    return { status := 200, contentType := "text/html", body := content }
  else if method == "GET" && path == "/style.css" then
    let content ← IO.FS.readFile "web/style.css"
    return { status := 200, contentType := "text/css", body := content }
  else if method == "GET" && (path == "/app.js" || path == "/app.ts") then
    let content ← IO.FS.readFile "web/app.js"
    return { status := 200, contentType := "application/javascript", body := content }

  -- 2. GET /v1/models
  else if method == "GET" && path == "/v1/models" then
    let models : ModelListResponse := {
      data := [
        { id := "koinon-omni-gemma" },
        { id := "gemini-2.0-flash-exp" }
      ]
    }
    return { status := 200, body := (toJson models).compress }

  -- 3. POST /v1/chat/completions (OpenAI & Hybrid Routing & RAG Context Ingestion)
  else if method == "POST" && path == "/v1/chat/completions" then
    match Json.parse body with
    | Except.ok j =>
        match (fromJson? j : Except String ChatCompletionRequest) with
        | Except.ok req =>
            let lyceumMessages : List Lyceum.Message := req.messages.map (fun m =>
              let r : Lyceum.Role := if m.role == "user" then .user else if m.role == "assistant" then .assistant else .system
              Lyceum.Message.mkText r m.content
            )
            let config : RouterConfig := default
            let infRes ← routeInference config req.model lyceumMessages false

            -- VectorDB RAG ノード検索
            let queryVector : Lyceum.Memory.Vector := { data := #[0.01, 0.05, 0.12, 0.88, 0.42, 0.99] }
            let retrieved := db.search queryVector 3 0.1
            let ragContextMsg := if retrieved.size > 0 then s!" [RAG Retrieved {retrieved.size} Vector Nodes]" else ""

            let respMsg : ChatMessage := {
              role := "assistant",
              content := s!"{infRes.content}{ragContextMsg} (VectorDB total entries: {db.entries.size})"
            }
            let resp : ChatCompletionResponse := {
              id := "chatcmpl-koinon-12345",
              created := 1700000000,
              model := infRes.modelUsed,
              choices := [{ index := 0, message := respMsg }],
              usage := { prompt_tokens := infRes.tokensUsed / 2, completion_tokens := infRes.tokensUsed / 2, total_tokens := infRes.tokensUsed }
            }
            return { status := 200, body := (toJson resp).compress }
        | Except.error err =>
            return { status := 400, body := s!"\{\"error\": \"Invalid ChatCompletionRequest: {err}\"}" }
    | Except.error err =>
        return { status := 400, body := s!"\{\"error\": \"Invalid JSON: {err}\"}" }

  -- 4. POST /v1/embeddings (OpenAI Embeddings API)
  else if method == "POST" && path == "/v1/embeddings" then
    match Json.parse body with
    | Except.ok j =>
        match (fromJson? j : Except String EmbeddingRequest) with
        | Except.ok req =>
            let dummyVector : List Float := [0.01, 0.05, 0.12, 0.88, 0.42, 0.99]
            let resp : EmbeddingResponse := {
              model := req.model,
              data := [{ index := 0, embedding := dummyVector }],
              usage := { prompt_tokens := req.input.length / 4 + 1, total_tokens := req.input.length / 4 + 1 }
            }
            return { status := 200, body := (toJson resp).compress }
        | Except.error err =>
            return { status := 400, body := s!"\{\"error\": \"Invalid EmbeddingRequest: {err}\"}" }
    | Except.error err =>
        return { status := 400, body := s!"\{\"error\": \"Invalid JSON: {err}\"}" }

  -- 5. POST /v1/rag/ingest (VectorDB Document Ingestion API)
  else if method == "POST" && path == "/v1/rag/ingest" then
    match Json.parse body with
    | Except.ok j =>
        match (fromJson? j : Except String RagIngestRequest) with
        | Except.ok req =>
            let assignedId := req.id.getD s!"doc-{db.entries.size + 1}"
            let entry : VectorEntry := {
              id := assignedId,
              text := s!"{req.title}: {req.content}",
              vector := { data := #[0.01, 0.05, 0.12, 0.88, 0.42, 0.99] },
              metadata := Json.mkObj [("title", Json.str req.title)]
            }
            let updatedDb := db.insert entry
            let resp : RagIngestResponse := {
              status := "ok",
              docId := assignedId,
              indexedEntries := updatedDb.entries.size
            }
            return { status := 200, body := (toJson resp).compress }
        | Except.error err =>
            return { status := 400, body := s!"\{\"error\": \"Invalid RagIngestRequest: {err}\"}" }
    | Except.error err =>
        return { status := 400, body := s!"\{\"error\": \"Invalid JSON: {err}\"}" }

  -- 6. POST /mcp (Model Context Protocol JSON-RPC)
  else if method == "POST" && (path == "/mcp" || path == "/v1/mcp") then
    let mcpRes ← handleMcpJsonRpc body
    match mcpRes with
    | some jsonStr => return { status := 200, contentType := "application/json", body := jsonStr }
    | none => return { status := 400, body := s!"\{\"error\": \"MCP Processing Failed\"}" }

  else
    return { status := 404, body := "{\"error\": \"Endpoint Not Found\"}" }

end Koinon.Server
