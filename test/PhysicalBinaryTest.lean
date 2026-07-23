import Koinon

namespace Koinon.Test.PhysicalBinaryTest

def testPhysicalExecution : IO Bool := do
  IO.println "  [Phase 3] Testing Physical Binary & Process Execution..."
  
  -- Execute build binary directly
  let child ← IO.Process.spawn {
    cmd := "./.lake/build/bin/koinon",
    stdout := .piped,
    stderr := .piped
  }
  
  let out ← child.stdout.readToEnd
  let _ ← child.wait

  if out.contains "Koinon Standalone LLM Omni-Server" && out.contains "OpenAI REST API" then
    IO.println "    [PASS] Physical Binary Output Verified."
    return true
  else
    IO.eprintln s!"    [FAIL] Physical Binary Output Mismatch: {out}"
    return false

end Koinon.Test.PhysicalBinaryTest
