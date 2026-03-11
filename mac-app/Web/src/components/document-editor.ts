import bridge from '../bridge/bridge-client';
import type { Document } from '../types/document';

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function debounce<T extends (...args: unknown[]) => unknown>(fn: T, delay: number): (...args: Parameters<T>) => void {
  let timer: ReturnType<typeof setTimeout>;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

export class DocumentEditor extends HTMLElement {
  private doc: Document | null = null;

  onSaved?: (doc: Document) => void;
  onDeleted?: (id: string) => void;

  connectedCallback(): void {
    this.style.cssText = 'display:flex;flex-direction:column;flex:1;overflow:hidden;';
    this.renderEmpty();
  }

  renderEmpty(): void {
    this.innerHTML = `
      <div class="editor-empty-state">
        <div class="empty-icon">📄</div>
        <p>Select a document or create a new one</p>
      </div>
    `;
  }

  async loadDocument(id: string): Promise<void> {
    this.innerHTML = '<div class="editor-empty-state"><div class="loading-spinner"></div></div>';
    try {
      this.doc = await bridge.documents.get(id);
      this.renderEditor();
    } catch {
      this.innerHTML = '<div class="editor-empty-state"><p class="text-muted">Failed to load document</p></div>';
    }
  }

  private renderEditor(): void {
    if (!this.doc) return;
    const doc = this.doc;

    this.innerHTML = `
      <div class="editor-toolbar">
        <input class="editor-title-input" id="doc-title" type="text"
               placeholder="Untitled" value="${escapeHtml(doc.title || '')}" />
        <button class="btn btn-ghost btn-icon" id="btn-delete-doc" title="Delete document">🗑</button>
      </div>
      <div class="editor-body">
        <textarea class="editor-textarea" id="doc-body"
                  placeholder="Start writing...">${escapeHtml(doc.body || '')}</textarea>
      </div>
    `;

    const titleInput = this.querySelector<HTMLInputElement>('#doc-title')!;
    const bodyTextarea = this.querySelector<HTMLTextAreaElement>('#doc-body')!;
    const deleteBtn = this.querySelector<HTMLButtonElement>('#btn-delete-doc')!;

    const save = debounce(async () => {
      try {
        const updated = await bridge.documents.update(doc.id, {
          title: titleInput.value,
          body: bodyTextarea.value,
        });
        this.doc = updated;
        if (this.onSaved) this.onSaved(updated);
      } catch {
        console.error('Failed to save document');
      }
    }, 800);

    titleInput.addEventListener('input', save);
    bodyTextarea.addEventListener('input', save);

    deleteBtn.addEventListener('click', async () => {
      if (!confirm('Delete this document? This cannot be undone.')) return;
      try {
        await bridge.documents.delete(doc.id);
        if (this.onDeleted) this.onDeleted(doc.id);
        this.renderEmpty();
      } catch {
        console.error('Failed to delete document');
      }
    });
  }
}

customElements.define('document-editor', DocumentEditor);
