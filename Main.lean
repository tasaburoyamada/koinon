import Koinon
import Koinon.Server.Router
import Koinon.Server.HttpServer
import Koinon.Protocol.MCP
import Lyceum.Memory.VectorDB

open Koinon.Server
open Koinon.Server.HttpServer
open Koinon.Protocol.MCP
open Lyceum.Memory

def main (args : List String) : IO Unit := do
  IO.println s!"=================================================="
  IO.println s!"  Koinon Standalone LLM Omni-Server v{Koinon.version}"
  IO.println s!"=================================================="
  IO.println "  [OpenAI REST API] Enabled (/v1/models, /v1/chat/completions, /v1/embeddings, /v1/rag/ingest)"
  IO.println "  [MCP JSON-RPC]    Enabled (/mcp, tools/list, tools/call)"
  IO.println "  [GGUF/Gemini Router] AVX-512 LeanTensor & Gemini 2.0 Active"
  IO.println "  [VectorDB RAG]    In-Memory & Persistent VectorDB Active"
  IO.println "=================================================="

  let dbRef ← IO.mkRef (default : VectorDB)

  if args.contains "--server-daemon" || args.contains "--listen" then
    let portStr := args.dropWhile (· != "--port") |>.get? 1 |>.getD "8080"
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
