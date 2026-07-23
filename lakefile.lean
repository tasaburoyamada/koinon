import Lake
open Lake DSL

package «koinon» where

require «lbir» from "../lbir"
require «nomos» from "../nomos"
require «LeanTensor» from "../LeanTensor"
require «Lyceum» from "../Lyceum"

@[default_target]
lean_lib «Koinon» where

lean_lib «test» where
  globs := #[.submodules `test]

@[default_target]
lean_exe «koinon» where
  root := `Main

lean_exe «server_test» where
  root := `test.ServerTest

lean_exe «test_driver» where
  root := `test.TestDriver
