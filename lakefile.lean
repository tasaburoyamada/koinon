import Lake
open Lake DSL

package «koinon» where

require «lbir» from "../lbir"
require «nomos» from "../nomos"
require «LeanTensor» from "../LeanTensor"
require «Lyceum» from "../Lyceum"

@[default_target]
lean_lib «Koinon» where

@[default_target]
lean_exe «koinon» where
  root := `Main

lean_exe «server_test» where
  root := `test.ServerTest

