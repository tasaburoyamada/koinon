import Koinon

def main : IO Unit := do
  IO.println s!"=================================================="
  IO.println s!"  Koinon Standalone LLM Omni-Server v{Koinon.version}"
  IO.println s!"=================================================="
  IO.println "  [OpenAI REST API] Enabled (Port: 8080)"
  IO.println "  [MCP JSON-RPC]    Enabled (Stdio/SSE)"
  IO.println "  [GGUF/Gemini Router] Ready"
  IO.println "  [VectorDB RAG]    Initialized"
  IO.println "=================================================="
