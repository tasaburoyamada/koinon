import Koinon
import Koinon.Protocol.OpenAI
import Koinon.Protocol.MCP
import Koinon.Engine.ModelManager
import Koinon.Server.Router
import Koinon.Server.HttpServer

namespace Koinon.Test.ScenarioE2ETest

open Koinon.Server
open Koinon.Server.HttpServer
open Koinon.Protocol.OpenAI
open Koinon.Protocol.MCP
open Koinon.Engine.ModelManager
open Lean

/-- Phase 4: 全機能統合シナリオ E2E ＆ レジリエンステスト -/
def testMultiTurnScenarioE2E : IO Bool := do
  IO.println "[Koinon Test] Running Phase 4: Full Multi-turn Scenario E2E & Resilience Test..."
  let mut db : Lyceum.Memory.VectorDB := default

  -- 1. シナリオ 1: POST /v1/rag/ingest ドキュメントインジェクション検証
  let ingestReq : RagIngestRequest := { title := "Nomos Spec", content := "Nomos verification laws" }
  let ingestBody := (toJson ingestReq).compress
  let resIngest ← handleRoute "POST" "/v1/rag/ingest" ingestBody db
  if resIngest.status != 200 || !resIngest.body.contains "indexedEntries" then
    IO.eprintln s!"  [FAIL] Scenario 1 RAG Ingest failed: {resIngest.body}"
    return false

  -- エントリの追加
  db := db.insert {
    id := "doc-1",
    text := "Nomos Spec: Nomos verification laws",
    vector := { data := #[0.01, 0.05, 0.12, 0.88, 0.42, 0.99] }
  }

  -- 2. シナリオ 2: マルチターン会話 ＆ VectorDB RAG コンテキスト注入検証
  let msg1 : ChatMessage := { role := "user", content := "Lean 4 の定理証明について教えてください。" }
  let req1 : ChatCompletionRequest := { model := "koinon-omni-gemma", messages := [msg1] }
  let body1 := (toJson req1).compress
  let res1 ← handleRoute "POST" "/v1/chat/completions" body1 db
  if res1.status != 200 || !res1.body.contains "RAG Retrieved" then
    IO.eprintln s!"  [FAIL] Scenario 2 Turn 1 RAG retrieval failed: {res1.body}"
    return false

  let msg2 : ChatMessage := { role := "assistant", content := "Lean 4 は依存型理論に基づく証明助手です。" }
  let msg3 : ChatMessage := { role := "user", content := "タクティクの例を1つ挙げてください。" }
  let req2 : ChatCompletionRequest := { model := "gemini-2.0-flash-exp", messages := [msg1, msg2, msg3] }
  let body2 := (toJson req2).compress
  let res2 ← handleRoute "POST" "/v1/chat/completions" body2 db
  if res2.status != 200 || !res2.body.contains "choices" then
    IO.eprintln s!"  [FAIL] Scenario 2 Turn 2 failed: status={res2.status}"
    return false

  -- 3. シナリオ 3: POST /v1/models/download Hugging Face プロビジョニング検証
  let dlReq : ModelDownloadRequest := { repoId := "google/gemma-2b-it-GGUF", fileName := "gemma-2b-it.gguf" }
  let dlBody := (toJson dlReq).compress
  let resDl ← handleRoute "POST" "/v1/models/download" dlBody db
  if resDl.status != 200 || !resDl.body.contains "targetPath" then
    IO.eprintln s!"  [FAIL] Scenario 3 Hugging Face Download API failed: {resDl.body}"
    return false

  -- 4. シナリオ 4: POST /mcp JSON-RPC koinon_download_model エージェントツール検証
  let mcpDlReq := "{\"jsonrpc\":\"2.0\",\"id\":103,\"method\":\"tools/call\",\"params\":{\"name\":\"koinon_download_model\",\"arguments\":{\"repo_id\":\"Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF\",\"file_name\":\"qwen2.5-coder-1.5b-instruct-q4_k_m.gguf\"}}}"
  let resMcpDl ← handleRoute "POST" "/mcp" mcpDlReq db
  if resMcpDl.status != 200 || !resMcpDl.body.contains "successfully provisioned" then
    IO.eprintln s!"  [FAIL] Scenario 4 MCP koinon_download_model tool failed: {resMcpDl.body}"
    return false

  -- 5. シナリオ 5: HTTP Raw Request Parser パース検証
  let rawHttp := "POST /v1/chat/completions HTTP/1.1\r\nHost: localhost:8080\r\n\r\n{\"model\":\"koinon-omni-gemma\",\"messages\":[]}"
  match parseHttpRequest rawHttp with
  | some parsed =>
    if parsed.method != "POST" || parsed.path != "/v1/chat/completions" then
      IO.eprintln s!"  [FAIL] Scenario 5 Raw HTTP Parser failed: {parsed.method} {parsed.path}"
      return false
  | none =>
    IO.eprintln "  [FAIL] Scenario 5 Raw HTTP Parser returned none"
    return false

  -- 6. シナリオ 6: Windows Exe インストーラーアセット (NSIS/Exe) 整合性検証
  let winBatExists ← System.FilePath.pathExists "installer/koinon-server.bat"
  let winNsiExists ← System.FilePath.pathExists "installer/koinon_setup.nsi"
  let winExeExists ← System.FilePath.pathExists "dist/Koinon_OmniServer_Setup_v0.1.0.exe"
  if !winBatExists || !winNsiExists || !winExeExists then
    IO.eprintln "  [FAIL] Scenario 6 Windows Setup Exe Verification Failed"
    return false

  -- 7. シナリオ 7: POST /v1/training/bitnet 1-bit (BitNet b1.58) QAT 蒸留学習 API 検証
  let trainReq : BitNetTrainRequest := { inFeatures := 8, outFeatures := 4, epochs := 3, learningRate := 0.01 }
  let trainBody := (toJson trainReq).compress
  let resTrain ← handleRoute "POST" "/v1/training/bitnet" trainBody db
  if resTrain.status != 200 || !resTrain.body.contains "BitNet b1.58" then
    IO.eprintln s!"  [FAIL] Scenario 7 BitNet Training API failed: {resTrain.body}"
    return false

  -- 8. シナリオ 8: 不正なパラメータ・壊れたJSON投入時の透過的エラーハンドリング検証
  let malformedJson := "{\"model\": \"unknown-model\", \"messages\": [broken_json_syntax"
  let resBad ← handleRoute "POST" "/v1/chat/completions" malformedJson db
  if resBad.status != 400 || !resBad.body.contains "error" then
    IO.eprintln s!"  [FAIL] Scenario 8 Resilience test failed: status={resBad.status}, body={resBad.body}"
    return false

  IO.println "  [PASS] Phase 4: Full Multi-turn Scenario E2E & Resilience Test PASSED (100%)."
  return true

end Koinon.Test.ScenarioE2ETest
