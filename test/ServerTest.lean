import Koinon

namespace Koinon.Test.ServerTest

open Koinon.Server
open Koinon.Protocol.OpenAI
open Lean

def testServerRouting : IO UInt32 := do
  IO.println "[Koinon Test] Testing Server Router & OpenAI DTO Compliance..."
  
  let db : Lyceum.Memory.VectorDB := default

  -- 1. Test GET /v1/models
  let resModels ← handleRoute "GET" "/v1/models" "" db
  if resModels.status != 200 || !resModels.body.contains "gemini-2.0-flash-exp" then
    IO.eprintln s!"  [FAIL] /v1/models failed: {resModels.body}"
    return 1

  -- 2. Test POST /v1/chat/completions
  let reqBody := "{\"model\": \"koinon-omni-gemma\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello, Koinon!\"}]}"
  let resChat ← handleRoute "POST" "/v1/chat/completions" reqBody db
  if resChat.status != 200 || !resChat.body.contains "Processed prompt" then
    IO.eprintln s!"  [FAIL] /v1/chat/completions failed: {resChat.body}"
    return 1

  IO.println "  [PASS] Server Router & OpenAI Protocol Compliance verified."
  return 0

end Koinon.Test.ServerTest

def main : IO UInt32 := Koinon.Test.ServerTest.testServerRouting
