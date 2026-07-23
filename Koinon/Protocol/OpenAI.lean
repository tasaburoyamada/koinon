import Lean
import Lean.Data.Json
import Lyceum.Types

namespace Koinon.Protocol.OpenAI

open Lean

/-- OpenAI 互換 Chat Completion リクエストメッセージ -/
structure ChatMessage where
  role : String
  content : String
deriving ToJson, FromJson, Repr, Inhabited

/-- OpenAI 互換 Chat Completion リクエスト -/
structure ChatCompletionRequest where
  model : String
  messages : List ChatMessage
  temperature : Option Float := none
  top_p : Option Float := none
  n : Option Nat := none
  stream : Option Bool := none
  stop : Option (List String) := none
  max_tokens : Option Nat := none
deriving ToJson, FromJson, Repr, Inhabited

/-- Chat Choice レスポンス -/
structure ChatChoice where
  index : Nat
  message : ChatMessage
  finish_reason : String := "stop"
deriving ToJson, FromJson, Repr, Inhabited

/-- Usage 統計 -/
structure UsageInfo where
  prompt_tokens : Nat := 0
  completion_tokens : Nat := 0
  total_tokens : Nat := 0
deriving ToJson, FromJson, Repr, Inhabited

/-- OpenAI 互換 Chat Completion レスポンス -/
structure ChatCompletionResponse where
  id : String
  object : String := "chat.completion"
  created : Nat
  model : String
  choices : List ChatChoice
  usage : UsageInfo := {}
deriving ToJson, FromJson, Repr, Inhabited

/-- モデル情報 -/
structure ModelObject where
  id : String
  object : String := "model"
  created : Nat := 1700000000
  owned_by : String := "koinon"
deriving ToJson, FromJson, Repr, Inhabited

/-- GET /v1/models レスポンス -/
structure ModelListResponse where
  object : String := "list"
  data : List ModelObject
deriving ToJson, FromJson, Repr, Inhabited

end Koinon.Protocol.OpenAI
