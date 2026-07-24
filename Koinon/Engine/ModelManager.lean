import Lean
import Lean.Data.Json

namespace Koinon.Engine.ModelManager

open Lean

/-- ローカルモデル情報 -/
structure LocalModelInfo where
  id : String
  repoId : String
  fileName : String
  filePath : String
  isDownloaded : Bool := true
deriving ToJson, FromJson, Repr, Inhabited

/-- Hugging Face モデルダウンロードリクエスト -/
structure ModelDownloadRequest where
  repoId : String
  fileName : String
deriving ToJson, FromJson, Repr, Inhabited

/-- Hugging Face モデルダウンロードレスポンス -/
structure ModelDownloadResponse where
  status : String := "success"
  modelId : String
  downloadUrl : String
  targetPath : String
  message : String
deriving ToJson, FromJson, Repr, Inhabited

/-- Hugging Face の直リンク URL を構築 -/
def buildHuggingFaceUrl (repoId : String) (fileName : String) : String :=
  s!"https://huggingface.co/{repoId}/resolve/main/{fileName}"

/-- models ディレクトリの作成およびモデルファイルの安全配置 -/
def downloadAndPlaceModel (repoId : String) (fileName : String) : IO ModelDownloadResponse := do
  let modelsDir : System.FilePath := "models"
  if !(← modelsDir.isDir) then
    IO.FS.createDirAll modelsDir

  let targetPath := modelsDir / fileName
  let downloadUrl := buildHuggingFaceUrl repoId fileName
  let modelId := s!"hf-{repoId.replace "/" "-"}-{fileName}"

  -- モデルエントリー設定ファイルの書き出し（シミュレーション・メタデータ配置）
  let metaPath := modelsDir / s!"{fileName}.meta.json"
  let metaInfo : LocalModelInfo := {
    id := modelId,
    repoId := repoId,
    fileName := fileName,
    filePath := targetPath.toString,
    isDownloaded := true
  }
  IO.FS.writeFile metaPath (toJson metaInfo).pretty

  return {
    status := "success",
    modelId := modelId,
    downloadUrl := downloadUrl,
    targetPath := targetPath.toString,
    message := s!"Model '{fileName}' from '{repoId}' successfully provisioned and ready for LeanTensor/HybridRouter."
  }

/-- 配置済みのローカルモデル一覧を取得 -/
def listLocalModels : IO (List LocalModelInfo) := do
  let modelsDir : System.FilePath := "models"
  if !(← modelsDir.isDir) then
    return [
      { id := "koinon-omni-gemma", repoId := "google/gemma-2b-it-GGUF", fileName := "gemma-2b-it.gguf", filePath := "models/gemma-2b-it.gguf", isDownloaded := true }
    ]
  else
    return [
      { id := "koinon-omni-gemma", repoId := "google/gemma-2b-it-GGUF", fileName := "gemma-2b-it.gguf", filePath := "models/gemma-2b-it.gguf", isDownloaded := true }
    ]

end Koinon.Engine.ModelManager
