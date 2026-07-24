import Koinon
import test.BlackboxTraceTest
import test.BoundaryTest
import test.PhysicalBinaryTest
import test.ScenarioE2ETest

namespace Koinon.Test.TestDriver

def main : IO UInt32 := do
  IO.println "=================================================="
  IO.println "  Koinon 4-Phase Hybrid Blackbox Test Suite       "
  IO.println "=================================================="

  -- Phase 1: Nomos Trace Validation
  let p1 ← Koinon.Test.BlackboxTraceTest.testServerBlackboxTrace
  if !p1 then
    IO.eprintln "  [FAIL] Phase 1: Nomos Trace Validation Failed"
    return 1

  -- Phase 2: Boundary Resilience
  let p2 ← Koinon.Test.BoundaryTest.testBoundaryResilience
  if !p2 then
    IO.eprintln "  [FAIL] Phase 2: Boundary Resilience Failed"
    return 1

  -- Phase 3: Physical Binary Execution
  let p3 ← Koinon.Test.PhysicalBinaryTest.testPhysicalExecution
  if !p3 then
    IO.eprintln "  [FAIL] Phase 3: Physical Binary Execution Failed"
    return 1

  -- Phase 4: Multi-turn Scenario E2E & Resilience
  let p4 ← Koinon.Test.ScenarioE2ETest.testMultiTurnScenarioE2E
  if !p4 then
    IO.eprintln "  [FAIL] Phase 4: Multi-turn Scenario E2E Failed"
    return 1

  IO.println "=================================================="
  IO.println "  ALL KOINON HYBRID TEST SUITES PASSED (100%)     "
  IO.println "=================================================="
  return 0

end Koinon.Test.TestDriver

def main : IO UInt32 := Koinon.Test.TestDriver.main
