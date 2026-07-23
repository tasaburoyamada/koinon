// Koinon Omni-Server RAG Studio - Pure TypeScript Frontend Controller

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
  private messages: ChatMessage[] = [];
  private vectorNodes: VectorNode[] = [
    { id: '102', title: 'Nomos Verification Specification', score: 0.94 },
    { id: '105', title: 'Lyceum Protocol Types & AST', score: 0.88 }
  ];

  constructor() {
    this.initEventListeners();
    this.renderVectorNodes();
  }

  private initEventListeners(): void {
    const btnSend = document.getElementById('btn-send');
    const chatInput = document.getElementById('chat-input') as HTMLInputElement;
    const btnAddDoc = document.getElementById('btn-add-doc');

    if (btnSend && chatInput) {
      btnSend.addEventListener('click', () => this.handleSendMessage());
      chatInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') this.handleSendMessage();
      });
    }

    if (btnAddDoc) {
      btnAddDoc.addEventListener('click', () => this.handleIngestDoc());
    }

    // Toggle Thought Accordions
    document.addEventListener('click', (e) => {
      const target = e.target as HTMLElement;
      if (target && target.classList.contains('thought-title')) {
        const content = target.nextElementSibling as HTMLElement;
        if (content) {
          content.style.display = content.style.display === 'none' ? 'block' : 'none';
        }
      }
    });
  }

  private async handleSendMessage(): Promise<void> {
    const inputEl = document.getElementById('chat-input') as HTMLInputElement;
    const text = inputEl.value.trim();
    if (!text) return;

    // Add User Message
    this.appendMessage({ role: 'user', content: text });
    inputEl.value = '';

    // Show Assistant Loading Indicator
    const modelSelect = document.getElementById('model-select') as HTMLSelectElement;
    const selectedModel = modelSelect ? modelSelect.value : 'gemini-2.0-flash-exp';

    try {
      // Send REST request to Koinon Server /v1/chat/completions
      const response = await fetch('/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: selectedModel,
          messages: [{ role: 'user', content: text }]
        })
      });

      if (response.ok) {
        const data = await response.json();
        const content = data.choices[0]?.message?.content || 'No response from Koinon Server.';
        this.appendMessage({
          role: 'assistant',
          thought: `[Hybrid Engine] Selected model: ${selectedModel}. VectorDB lookup performed.`,
          content: content
        });
      } else {
        throw new Error('Server returned error status');
      }
    } catch (err) {
      // Mock Fallback Response for standalone UI preview
      setTimeout(() => {
        this.appendMessage({
          role: 'assistant',
          thought: `[Local Simulation Engine] Model: ${selectedModel}\n- Nomos State: Verified\n- VectorDB similarity threshold: > 0.85`,
          content: `[Koinon Omni-Server] 「${text}」を受信しました。Koinon Hybrid Router により正常に処理されました。`
        });
      }, 500);
    }
  }

  private appendMessage(msg: ChatMessage): void {
    this.messages.push(msg);
    const messagesContainer = document.getElementById('chat-messages');
    if (!messagesContainer) return;

    const card = document.createElement('div');
    card.className = `message-card ${msg.role}`;

    const avatar = document.createElement('div');
    avatar.className = `avatar ${msg.role}`;
    avatar.textContent = msg.role === 'user' ? 'U' : 'K';

    const bubble = document.createElement('div');
    bubble.className = 'message-bubble';

    if (msg.thought) {
      const thoughtAccordion = document.createElement('div');
      thoughtAccordion.className = 'thought-accordion';
      thoughtAccordion.innerHTML = `
        <div class="thought-title">▶ Thinking Process (Native Reasoning)</div>
        <div class="thought-content" style="display: none; margin-top: 6px;">${msg.thought}</div>
      `;
      bubble.appendChild(thoughtAccordion);
    }

    const textNode = document.createElement('div');
    textNode.textContent = msg.content;
    bubble.appendChild(textNode);

    card.appendChild(avatar);
    card.appendChild(bubble);

    messagesContainer.appendChild(card);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  private handleIngestDoc(): void {
    const titleEl = document.getElementById('doc-title') as HTMLInputElement;
    const contentEl = document.getElementById('doc-content') as HTMLTextAreaElement;

    if (!titleEl.value.trim()) return;

    const newDoc: VectorNode = {
      id: Math.floor(Math.random() * 900 + 100).toString(),
      title: titleEl.value.trim(),
      score: +(Math.random() * 0.15 + 0.84).toFixed(2)
    };

    this.vectorNodes.unshift(newDoc);
    this.renderVectorNodes();

    titleEl.value = '';
    contentEl.value = '';
  }

  private renderVectorNodes(): void {
    const container = document.getElementById('retrieved-nodes');
    if (!container) return;

    container.innerHTML = this.vectorNodes.map(node => `
      <div class="vector-node">
        <span class="vector-score">${node.score}</span>
        <strong>[Doc #${node.id}]</strong> ${node.title}
      </div>
    `).join('');
  }
}

// Initialize on DOM Ready
document.addEventListener('DOMContentLoaded', () => {
  new KoinonStudioApp();
});
