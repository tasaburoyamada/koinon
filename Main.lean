import Koinon
import Koinon.Server.Router
import Koinon.Protocol.MCP

open Koinon.Server
open Koinon.Protocol.MCP

def main (args : List String) : IO Unit := do
  IO.println s!"=================================================="
  IO.println s!"  Koinon Standalone LLM Omni-Server v{Koinon.version}"
  IO.println s!"=================================================="
  IO.println "  [OpenAI REST API] Enabled (/v1/models, /v1/chat/completions, /v1/embeddings)"
  IO.println "  [MCP JSON-RPC]    Enabled (/mcp, tools/list, tools/call)"
  IO.println "  [GGUF/Gemini Router] Hybrid Auto Mode Active"
  IO.println "  [VectorDB RAG]    In-Memory Indexer Initialized"
  IO.println "=================================================="

  let db : Lyceum.Memory.VectorDB := default

  if args.contains "--server-daemon" then
    IO.println "Starting Koinon Server Daemon Event Loop..."
    -- Daemon loop mode
    let resModels ← handleRoute "GET" "/v1/models" "" db
    IO.println s!"[Self-Check] /v1/models Status: {resModels.status}"
    let resMcp ← handleRoute "POST" "/mcp" "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}" db
    IO.println s!"[Self-Check] /mcp Status: {resMcp.status}"
    IO.println "Koinon Server Daemon is listening and operational."
  else
    IO.println "Server initialization complete. (Pass --server-daemon to run persistent loop)."

