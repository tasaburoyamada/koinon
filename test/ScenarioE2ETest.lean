import Koinon
import Koinon.Protocol.OpenAI
import Koinon.Protocol.MCP
import Koinon.Server.Router

namespace Koinon.Test.ScenarioE2ETest

open Koinon.Server
open Koinon.Protocol.OpenAI
open Koinon.Protocol.MCP
open Lean

/-- Phase 4: 全機能統合シナリオ E2E ＆ レジリエンステスト -/
def testMultiTurnScenarioE2E : IO Bool := do
  IO.println "[Koinon Test] Running Phase 4: Full Multi-turn Scenario E2E & Resilience Test..."
  let db : Lyceum.Memory.VectorDB := default

  -- 1. シナリオ 1: マルチターン会話と Hybrid 推論エンジン追従検証
  let msg1 : ChatMessage := { role := "user", content := "Lean 4 の定理証明について教えてください。" }
  let req1 : ChatCompletionRequest := { model := "koinon-omni-gemma", messages := [msg1] }
  let body1 := (toJson req1).compress
  let res1 ← handleRoute "POST" "/v1/chat/completions" body1 db
  if res1.status != 200 || !res1.body.contains "choices" then
    IO.eprintln s!"  [FAIL] Scenario 1 Turn 1 failed status={res1.status}"
    return false

  let msg2 : ChatMessage := { role := "assistant", content := "Lean 4 は依存型理論に基づく証明助手です。" }
  let msg3 : ChatMessage := { role := "user", content := "タクティクの例を1つ挙げてください。" }
  let req2 : ChatCompletionRequest := { model := "gemini-2.0-flash-exp", messages := [msg1, msg2, msg3] }
  let body2 := (toJson req2).compress
  let res2 ← handleRoute "POST" "/v1/chat/completions" body2 db
  if res2.status != 200 || !res2.body.contains "choices" then
    IO.eprintln s!"  [FAIL] Scenario 1 Turn 2 failed status={res2.status}"
    return false

  -- 2. シナリオ 2: POST /v1/embeddings API 動作検証
  let embReq : EmbeddingRequest := { model := "koinon-omni-gemma", input := "Koinon VectorDB Test Text" }
  let embBody := (toJson embReq).compress
  let resEmb ← handleRoute "POST" "/v1/embeddings" embBody db
  if resEmb.status != 200 || !resEmb.body.contains "embedding" then
    IO.eprintln s!"  [FAIL] Scenario 2 Embeddings API failed status={resEmb.status}, body={resEmb.body}"
    return false

  -- 3. シナリオ 3: POST /mcp JSON-RPC エージェントツール検証
  let mcpListReq := "{\"jsonrpc\":\"2.0\",\"id\":101,\"method\":\"tools/list\"}"
  let resMcpList ← handleRoute "POST" "/mcp" mcpListReq db
  if resMcpList.status != 200 || !resMcpList.body.contains "koinon_chat" then
    IO.eprintln s!"  [FAIL] Scenario 3 MCP tools/list failed: {resMcpList.body}"
    return false

  let mcpCallReq := "{\"jsonrpc\":\"2.0\",\"id\":102,\"method\":\"tools/call\",\"params\":{\"name\":\"koinon_chat\",\"arguments\":{\"prompt\":\"Hello\"}}}"
  let resMcpCall ← handleRoute "POST" "/mcp" mcpCallReq db
  if resMcpCall.status != 200 || !resMcpCall.body.contains "Executed" then
    IO.eprintln s!"  [FAIL] Scenario 3 MCP tools/call failed: {resMcpCall.body}"
    return false

  -- 4. シナリオ 4: 不正なパラメータ・壊れたJSON投入時の透過的エラーハンドリング検証
  let malformedJson := "{\"model\": \"unknown-model\", \"messages\": [broken_json_syntax"
  let resBad ← handleRoute "POST" "/v1/chat/completions" malformedJson db
  if resBad.status != 400 || !resBad.body.contains "error" then
    IO.eprintln s!"  [FAIL] Scenario 4 Resilience test failed: status={resBad.status}, body={resBad.body}"
    return false

  -- 5. シナリオ 5: Web UI アセット提供の応答性検証
  let resIndex ← handleRoute "GET" "/" "" db
  if resIndex.status != 200 || !resIndex.body.contains "Koinon Studio" then
    IO.eprintln s!"  [FAIL] Scenario 5 Root Web Route failed: status={resIndex.status}"
    return false

  IO.println "  [PASS] Phase 4: Full Multi-turn Scenario E2E & Resilience Test PASSED (100%)."
  return true

end Koinon.Test.ScenarioE2ETest
