# Koinon Web UI 設計書 (LlamaIndex UI Style)

## 1. 概要
**Koinon RAG Studio Web UI** は、LlamaIndex や Modern RAG Dashboard にインスパイアされた、HTML5 + Vanilla CSS + Pure TypeScript/JS による軽量かつ極めてモダンな Web UI フロントエンドである。

本設計書は、画面コンポーネント構成、CSS デザイントークン、Pure TS クラス構造、および Thinking Process / VectorDB ノードの動的バインディング仕様を定義する。

---

## 2. デザインシステム (Design Tokens & Ergonomics)

### 2.1. カラーパレット (Dark Glassmorphism Theme)
```css
:root {
  --bg-primary: #0a0c10;       /* 漆黒ベース背景 */
  --bg-secondary: #121620;     /* サイドバー・ヘッダー背景 */
  --bg-card: rgba(22, 28, 42, 0.7); /* グラスモフィズムカード背景 */
  
  --accent-primary: #6366f1;   /* Indigo メインアクセント */
  --accent-secondary: #a855f7; /* Purple グラデーション用 */
  --accent-cyan: #06b6d4;      /* Cyan ステータス/ノード用 */
  --accent-emerald: #10b981;   /* Emerald 成功・高類似度用 */
  
  --font-sans: 'Inter', sans-serif;
  --font-mono: 'Fira Code', monospace;
}
```

---

## 3. 画面レイアウト・コンポーネント構成

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [Brand Logo] Koinon Studio   [Status: Online]  [Model: Gemini 2.0 Flash]    │
├──────────────┬──────────────────────────────────────────────┬───────────────┤
│ Navigation   │  Chat Messages                               │ VectorDB      │
│ - RAG Chat   │  ┌────────────────────────────────────────┐  │ Indexer       │
│ - VectorDB   │  │ [Thinking Process (Native Reasoning)]  │  │ ┌───────────┐ │
│ - MCP Tools  │  │  Loaded Nomos State & VectorDB index.  │  │ │ Doc Title │ │
│              │  └────────────────────────────────────────┘  │ └───────────┘ │
│ Backend      │  Hello! Welcome to Koinon Studio.            │ Retrieved     │
│ Status       │                                              │ Nodes         │
│ - Hybrid Auto│                                              │ [0.94] Doc#102│
│ - Nomos OK   │ ┌──────────────────────────────────────────┐ │ [0.88] Doc#105│
│              │ │ Input prompt...                 [Send] │ │               │
└──────────────┴──────────────────────────────────────────────┴───────────────┘
```

---

## 4. TypeScript クラス構造 (`KoinonStudioApp`)

```typescript
interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
  thought?: string;
}

interface VectorNode {
  id: string;
  title: string;
  score: number;
}

class KoinonStudioApp {
  private messages: ChatMessage[];
  private vectorNodes: VectorNode[];

  constructor();
  private initEventListeners(): void;
  private async handleSendMessage(): Promise<void>;
  private appendMessage(msg: ChatMessage): void;
  private handleIngestDoc(): void;
  private renderVectorNodes(): void;
}
```

---

## 5. インタラクティブ機能仕様

1. **Native Reasoning (Thought) アコーディオン**:
   - assistant ロールメッセージに `thought` フィールドが含まれる場合、`▶ Thinking Process` ヘッダーをレンダリング。
   - アコーディオンをクリックすることで `display: block / none` が切り替わり、内部思考を展開。

2. **VectorDB ノードインスペクター**:
   - 入力されたドキュメントタイトル・本文を受け取り、コサイン類似度スコア（`0.84 ~ 0.99`）を伴う視覚ノードとして動的挿入。

3. **REST API フォールバック機能**:
   - オンライン時は `/v1/chat/completions` に即座に fetch 発行。
   - ローカルスタンドアロンプレビュー時は、自動フォールバックにより疑似思考ログおよび処理応答を返答。
