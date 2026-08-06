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

/-- Chat Completion Chunk Delta -/
structure ChatDelta where
  role : Option String := none
  content : Option String := none
deriving ToJson, FromJson, Repr, Inhabited

/-- Chat Chunk Choice -/
structure ChunkChoice where
  index : Nat
  delta : ChatDelta
  finish_reason : Option String := none
deriving ToJson, FromJson, Repr, Inhabited

/-- OpenAI 互換 Streaming Chat Completion Chunk -/
structure ChatCompletionChunk where
  id : String
  object : String := "chat.completion.chunk"
  created : Nat
  model : String
  choices : List ChunkChoice
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

/-- POST /v1/embeddings リクエスト -/
structure EmbeddingRequest where
  model : String
  input : String
  user : Option String := none
deriving ToJson, FromJson, Repr, Inhabited

/-- Embedding データオブジェクト -/
structure EmbeddingObject where
  object : String := "embedding"
  index : Nat := 0
  embedding : List Float
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/embeddings レスポンス -/
structure EmbeddingResponse where
  object : String := "list"
  data : List EmbeddingObject
  model : String
  usage : UsageInfo := {}
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/rag/ingest ドキュメントインジェクションリクエスト -/
structure RagIngestRequest where
  id : Option String := none
  title : String
  content : String
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/rag/ingest レスポンス -/
structure RagIngestResponse where
  status : String := "ok"
  docId : String
  indexedEntries : Nat
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/training/bitnet リクエスト -/
structure BitNetTrainRequest where
  inFeatures : Nat := 8
  outFeatures : Nat := 4
  epochs : Nat := 5
  learningRate : Float := 0.01
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/training/bitnet レスポンス -/
structure BitNetTrainResponse where
  status : String := "success"
  initialLoss : Float
  finalLoss : Float
  trainedEpochs : Nat
  gamma : Float
  message : String
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/chat/mla リクエスト -/
structure MLAChatRequest where
  prompt : String
  pos : Option Nat := none
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/chat/mla レスポンス -/
structure MLAChatResponse where
  status : String := "success"
  compressedKvDim : Nat
  qLatentDim : Nat
  absorbedCalculation : Bool := true
  nomosInvariantVerified : Bool
  response : String
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/chat/dsa リクエスト -/
structure DSAChatRequest where
  prompt : String
  topK : Option Nat := none
  pos : Option Nat := none
deriving ToJson, FromJson, Repr, Inhabited

/-- POST /v1/chat/dsa レスポンス -/
structure DSAChatResponse where
  status : String := "success"
  topKSelected : Nat
  sparsityRatio : Float
  nomosInvariantVerified : Bool
  response : String
deriving ToJson, FromJson, Repr, Inhabited

end Koinon.Protocol.OpenAI
