import Koinon

namespace Koinon.Test.BoundaryTest

open Koinon.Server
open Lean

def testBoundaryResilience : IO Bool := do
  IO.println "  [Phase 2] Testing Universal Boundary Resilience..."
  let db : Lyceum.Memory.VectorDB := default

  -- 1. Invalid JSON Test
  let res1 ← handleRoute "POST" "/v1/chat/completions" "{invalid_json}" db
  if res1.status != 400 || !res1.body.contains "Invalid JSON" then
    IO.eprintln s!"    [FAIL] Expected 400 for Invalid JSON, got: {res1.status}"
    return false

  -- 2. Non-existent Endpoint Test
  let res2 ← handleRoute "GET" "/v1/non_existent" "" db
  if res2.status != 404 || !res2.body.contains "Endpoint Not Found" then
    IO.eprintln s!"    [FAIL] Expected 404 for non-existent endpoint, got: {res2.status}"
    return false

  -- 3. Empty Messages Chat Completion Request
  let res3 ← handleRoute "POST" "/v1/chat/completions" "{\"model\": \"koinon-omni-gemma\", \"messages\": []}" db
  if res3.status != 200 then
    IO.eprintln s!"    [FAIL] Expected 200 for empty messages, got: {res3.status}"
    return false

  IO.println "    [PASS] All Boundary Resilience Cases Passed."
  return true

end Koinon.Test.BoundaryTest
