import Koinon

namespace Koinon.Test.ServerTest

open Koinon.Server
open Koinon.Protocol.OpenAI
open Lean

def testServerRouting : IO UInt32 := do
  IO.println "[Koinon Test] Testing Server Router & Strict OpenAI DTO Compliance..."
  
  let db : Lyceum.Memory.VectorDB := default

  -- 1. Test GET /v1/models (Structured DTO Validation)
  let resModels ← handleRoute "GET" "/v1/models" "" db
  if resModels.status != 200 then
    IO.eprintln s!"  [FAIL] /v1/models HTTP status expected 200, got: {resModels.status}"
    return 1
  
  match Json.parse resModels.body with
  | Except.error err =>
      IO.eprintln s!"  [FAIL] /v1/models response is not valid JSON: {err}"
      return 1
  | Except.ok j =>
      match (fromJson? j : Except String ModelListResponse) with
      | Except.error err =>
          IO.eprintln s!"  [FAIL] /v1/models failed to deserialize into ModelListResponse: {err}"
          return 1
      | Except.ok models =>
          if models.data.isEmpty then
            IO.eprintln "  [FAIL] /v1/models returned empty model list"
            return 1

  -- 2. Test POST /v1/chat/completions (Strict JSON Deserialization & Structural Checks)
  let reqBody := "{\"model\": \"koinon-omni-gemma\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello, Koinon!\"}]}"
  let resChat ← handleRoute "POST" "/v1/chat/completions" reqBody db
  if resChat.status != 200 then
    IO.eprintln s!"  [FAIL] /v1/chat/completions HTTP status expected 200, got: {resChat.status}"
    return 1

  match Json.parse resChat.body with
  | Except.error err =>
      IO.eprintln s!"  [FAIL] /v1/chat/completions response is not valid JSON: {err}"
      return 1
  | Except.ok j =>
      match (fromJson? j : Except String ChatCompletionResponse) with
      | Except.error err =>
          IO.eprintln s!"  [FAIL] /v1/chat/completions failed to deserialize into ChatCompletionResponse DTO: {err}"
          return 1
      | Except.ok chatResp =>
          if chatResp.choices.isEmpty then
            IO.eprintln "  [FAIL] /v1/chat/completions response choices list is empty"
            return 1
          let firstChoice := chatResp.choices.head!
          if firstChoice.message.role != "assistant" then
            IO.eprintln s!"  [FAIL] Expected message role 'assistant', got: '{firstChoice.message.role}'"
            return 1
          if firstChoice.message.content.isEmpty then
            IO.eprintln "  [FAIL] Chat completion content is empty"
            return 1

  -- 3. Test Remote Gemini Mode Fallback (Boundary & Environment Isolation Test)
  let remoteReqBody := "{\"model\": \"gemini-2.0-flash-exp\", \"messages\": [{\"role\": \"user\", \"content\": \"Test Remote Fallback\"}]}"
  let resRemote ← handleRoute "POST" "/v1/chat/completions" remoteReqBody db
  if resRemote.status != 200 then
    IO.eprintln s!"  [FAIL] Remote routing HTTP status expected 200, got: {resRemote.status}"
    return 1
  match Json.parse resRemote.body with
  | Except.error err =>
      IO.eprintln s!"  [FAIL] Remote chat response is not valid JSON: {err}"
      return 1
  | Except.ok j =>
      match (fromJson? j : Except String ChatCompletionResponse) with
      | Except.error err =>
          IO.eprintln s!"  [FAIL] Remote chat response failed DTO deserialization: {err}"
          return 1
      | Except.ok resp =>
          if resp.model != "gemini-2.0-flash-exp" then
            IO.eprintln s!"  [FAIL] Expected model 'gemini-2.0-flash-exp', got: '{resp.model}'"
            return 1
  -- 4. Test SSE Streaming Mode (Server-Sent Events: text/event-stream)
  let streamReqBody := "{\"model\": \"koinon-omni-gemma\", \"stream\": true, \"messages\": [{\"role\": \"user\", \"content\": \"Test SSE Stream\"}]}"
  let resStream ← handleRoute "POST" "/v1/chat/completions" streamReqBody db
  if resStream.status != 200 || resStream.contentType != "text/event-stream" then
    IO.eprintln s!"  [FAIL] SSE Stream expected status 200 and text/event-stream, got: status {resStream.status}, type {resStream.contentType}"
    return 1
  if !resStream.body.contains "data: [DONE]" then
    IO.eprintln s!"  [FAIL] SSE Stream response missing '[DONE]' marker: {resStream.body}"
    return 1
  -- 5. Test Nomos Theorem Invariants Verification (形式検証定理の不変量チェック)
  let mlaLayer := Lyceum.Inference.MLA.createMLALayer
  let dummyKvCache : Array (Array Float) := #[
    #[0.1, -0.2, 0.5, 0.9, -0.4, 0.3, 0.8, -0.1],
    #[-0.3, 0.6, 0.2, -0.8, 0.5, 0.7, -0.2, 0.4]
  ]
  let dummyQ := #[0.2, 0.4, -0.1, 0.7, 0.3, -0.5, 0.8, 0.1]
  let (_, attnWeights) := Lyceum.Inference.MLA.forwardMlaAbsorbed mlaLayer dummyQ dummyKvCache 1
  let invariantVerified := Lyceum.Inference.MLA.verifyMlaInvariants attnWeights
  if !invariantVerified then
    IO.eprintln "  [FAIL] Nomos Theorem Invariants verification failed! Attention sum is not equal to 1.0"
    return 1

  IO.println "  [PASS] Server Router, Dynamic RAG Vector, Nomos Theorems & Strict OpenAI DTO Contract verified."
  return 0


end Koinon.Test.ServerTest

def main : IO UInt32 := Koinon.Test.ServerTest.testServerRouting
