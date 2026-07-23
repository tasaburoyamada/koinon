import Lean
import Lean.Data.Json
import Koinon.Protocol.OpenAI
import Koinon.Engine.HybridRouter
import Lyceum.Memory.VectorDB

namespace Koinon.Server

open Lean
open Koinon.Protocol.OpenAI
open Koinon.Engine

structure HttpResponse where
  status : Nat := 200
  contentType : String := "application/json"
  body : String
deriving Repr, Inhabited

/-- REST API & MCP リクエストを処理するメインルーター -/
def handleRoute (method : String) (path : String) (body : String) (db : Lyceum.Memory.VectorDB) : IO HttpResponse := do
  if method == "GET" && path == "/v1/models" then
    let models : ModelListResponse := {
      data := [
        { id := "koinon-omni-gemma" },
        { id := "gemini-2.0-flash-exp" }
      ]
    }
    return { status := 200, body := (toJson models).compress }
  else if method == "POST" && path == "/v1/chat/completions" then
    match Json.parse body with
    | Except.ok j =>
        match (fromJson? j : Except String ChatCompletionRequest) with
        | Except.ok req =>
            let respMsg : ChatMessage := {
              role := "assistant",
              content := s!"[Koinon Omni-Server] Processed prompt with model '{req.model}'. Received {req.messages.length} messages."
            }
            let resp : ChatCompletionResponse := {
              id := "chatcmpl-koinon-12345",
              created := 1700000000,
              model := req.model,
              choices := [{ index := 0, message := respMsg }]
            }
            return { status := 200, body := (toJson resp).compress }
        | Except.error err =>
            return { status := 400, body := s!"\{\"error\": \"Invalid ChatCompletionRequest: {err}\"}" }
    | Except.error err =>
        return { status := 400, body := s!"\{\"error\": \"Invalid JSON: {err}\"}" }
  else
    return { status := 404, body := "{\"error\": \"Endpoint Not Found\"}" }


end Koinon.Server
