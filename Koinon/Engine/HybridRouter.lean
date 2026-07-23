import Lyceum
import Lyceum.Inference.Backend

namespace Koinon.Engine

open Lyceum

/-- ハイブリッドエンジン動作モード -/
inductive EngineMode where
  | localGguf
  | remoteGemini
  | hybridAuto
deriving Repr, BEq, Inhabited

/-- ハイブリッドルーター設定 -/
structure RouterConfig where
  mode : EngineMode := .hybridAuto
  maxLocalContextTokens : Nat := 4096
  geminiModelName : String := "gemini-2.0-flash-exp"
deriving Repr, Inhabited

/-- リクエスト内容を判定し、最適な LLM バックエンドを選択する -/
def selectBackend (config : RouterConfig) (history : List Message) : IO GeminiClient := do
  return GeminiClient.mk "https://generativelanguage.googleapis.com" "" (some config.geminiModelName)

end Koinon.Engine
