import Koinon
import Koinon.Server.Router
import Koinon.Server.HttpServer
import Koinon.Protocol.MCP
import Koinon.Engine.ModelManager
import Lyceum.Memory.VectorDB

open Koinon.Server
open Koinon.Server.HttpServer
open Koinon.Protocol.MCP
open Koinon.Engine.ModelManager
open Lyceum.Memory

def main (args : List String) : IO Unit := do
  IO.println s!"=================================================="
  IO.println s!"  Koinon Standalone LLM Omni-Server v{Koinon.version}"
  IO.println s!"=================================================="
  IO.println "  [OpenAI REST API] Enabled (/v1/models, /v1/chat/completions, /v1/embeddings, /v1/rag/ingest, /v1/models/download)"
  IO.println "  [MCP JSON-RPC]    Enabled (/mcp, tools/list, tools/call, koinon_download_model)"
  IO.println "  [GGUF/Gemini Router] AVX-512 LeanTensor & Gemini 2.0 Active"
  IO.println "  [HuggingFace Hub] Auto-downloader & provisioning enabled"
  IO.println "  [VectorDB RAG]    In-Memory & Persistent VectorDB Active"
  IO.println "=================================================="

  -- 起動時自動プロビジョニングチェック
  if args.contains "--fetch-model" then
    let repoId := args.dropWhile (· != "--fetch-model") |>.drop 1 |>.head?.getD "google/gemma-2b-it-GGUF"
    let fileName := args.dropWhile (· != "--fetch-model") |>.drop 2 |>.head?.getD "gemma-2b-it.gguf"
    IO.println s!"[HuggingFace Auto-Provisioning] Fetching model '{fileName}' from '{repoId}'..."
    let dlRes ← downloadAndPlaceModel repoId fileName
    IO.println s!"[HuggingFace Auto-Provisioning] {dlRes.message}"

  let dbRef ← IO.mkRef (default : VectorDB)

  if args.contains "--server-daemon" || args.contains "--listen" then
    let portStr := args.dropWhile (· != "--port") |>.drop 1 |>.head?.getD "8080"
    let port := portStr.toNat?.getD 8080 |>.toUInt16
    IO.println s!"Starting Koinon Standalone HTTP Server on port {port}..."
    startHttpServer port dbRef
  else
    let currentDb ← dbRef.get
    let resModels ← handleRoute "GET" "/v1/models" "" currentDb
    IO.println s!"[Self-Check] GET /v1/models -> Status {resModels.status}"
    let resMcp ← handleRoute "POST" "/mcp" "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}" currentDb
    IO.println s!"[Self-Check] POST /mcp -> Status {resMcp.status}"
    IO.println "Server self-check complete. Pass --server-daemon --port 8080 to start real socket listener."
