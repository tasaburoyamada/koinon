# Koinon 現在の開発状況 (Current Status)

## 最新更新日時
2026-07-24

## 1. 完了した作業項目
- **Hugging Face Hub モデルプロビジョニングエンジン (`Koinon.Engine.ModelManager`)**:
  - リポジトリ ID とファイル名から HF Hub 直リンク URL を動的生成し、`models/` ディレクトリへ安全に配置・設定メタデータ (`.meta.json`) を生成するダウンローダーを新設。
- **OpenAI 互換 REST API (`POST /v1/models/download`)**:
  - 外部クライアントや Web UI から任意の GGUF/LLM モデルのダウンロード・配置要求を受理するエンドポイントを追加。
- **MCP Agent Tool (`koinon_download_model`) 統合**:
  - `Koinon.Protocol.MCP` のエージェントツール一覧に `koinon_download_model` を追加。Antigravity や Pakila などの AI エージェントが会話から自律的にモデルを取得可能に拡張。
- **スタートアップ CLI プロビジョニング (`Main.lean`)**:
  - `--fetch-model <repo_id> <file_name>` フラグによるサーバー起動時モデル自動配置に対応。
- **Web Studio UI Model Store (`web/index.html`, `web/app.js`)**:
  - Web UI に「Hugging Face Model Store」カードを追加。ワンクリックダウンロードおよびモデル選択肢の自動動的更新をサポート。
- **4 段階ハイブリッド検証テストスイート (Phase 1〜4 100% PASS)**:
  - `lake exe test_driver` による全 159 ジョブの物理コンパイルおよび全 6 シナリオ（RAG Ingest, Multi-turn RAG Chat, HF Download API, MCP `koinon_download_model` tool, Raw HTTP Parser, Malformed JSON Resilience）が 100% 通過。




