# Koinon Standalone LLM Omni-Server - Windows セットアップガイド

## 1. 概要
本パッケージは、Windows 環境上で **Koinon LLM Omni-Server**（OpenAI 互換 REST API, MCP JSON-RPC 2.0, VectorDB RAG, Hugging Face Hub ダウンローダー）を簡単にセットアップ・起動するためのインストーラーパックです。

---

## 2. インストール方法（選べる 3 つの手順）

### 方法 A: ワンクリック自動セットアップ (PowerShell)
1. フォルダ内の `install.ps1` を右クリック ➔ **「PowerShell で実行」** を選択。
2. 自動的に `%LocalAppData%\Koinon` に配置され、デスクトップに起動ショートカットが作成されます。

### 方法 B: Inno Setup 定式インストーラー
1. `Koinon_OmniServer_Setup_v0.1.0.exe` (構築済みの installer) を実行。
2. 画面の指示に従ってインストールを完了します。

### 方法 C: ポータブル起動
1. 本フォルダを任意の場所に配置。
2. `koinon-server.bat` をダブルクリックして起動します。

---

## 3. 起動確認と Web UI アクセス
1. サーバー起動後、ブラウザで以下の URL を開きます:
   - **Koinon Studio Web UI**: `http://localhost:8080/`
2. REST API エンドポイント:
   - `http://localhost:8080/v1/models`
   - `http://localhost:8080/v1/chat/completions`
   - `http://localhost:8080/v1/embeddings`
   - `http://localhost:8080/v1/models/download`
3. MCP (Model Context Protocol) エンドポイント:
   - `http://localhost:8080/mcp`
