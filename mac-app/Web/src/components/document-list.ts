import bridge from '../bridge/bridge-client';
import type { DocumentSummary } from '../types/document';

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
  } catch {
    return iso;
  }
}

export class DocumentList extends HTMLElement {
  private documents: DocumentSummary[] = [];
  private selectedId: string | null = null;

  onSelect?: (id: string) => void;

  connectedCallback(): void {
    this.style.cssText = 'display:flex;flex-direction:column;height:100%;';
    this.loadDocuments();
  }

  async loadDocuments(): Promise<void> {
    try {
      this.documents = await bridge.documents.list();
      this.renderList();
    } catch {
      this.innerHTML = '<div class="empty-state"><p class="text-muted">Failed to load documents</p></div>';
    }
  }

  setSelected(id: string | null): void {
    this.selectedId = id;
    this.querySelectorAll('.doc-item').forEach(el => {
      (el as HTMLElement).classList.toggle('selected', (el as HTMLElement).dataset['id'] === id);
    });
  }

  private renderList(): void {
    if (!this.documents.length) {
      this.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">📝</div>
          <h3>No Documents</h3>
          <p>Create your first document to get started</p>
        </div>
      `;
      return;
    }

    this.innerHTML = this.documents.map(doc => `
      <div class="doc-item ${doc.id === this.selectedId ? 'selected' : ''}" data-id="${escapeHtml(doc.id)}">
        <div class="doc-title">${escapeHtml(doc.title || 'Untitled')}</div>
        <div class="doc-snippet">${escapeHtml(doc.body_snippet || '')}</div>
        <div class="doc-meta">${formatDate(doc.updatedAt)}</div>
        ${doc.tags?.length ? `
          <div class="doc-tags">
            ${doc.tags.slice(0, 3).map(t => `
              <span class="tag-chip">
                <span class="tag-dot" style="background:${escapeHtml(t.color)}"></span>
                ${escapeHtml(t.name)}
              </span>
            `).join('')}
          </div>
        ` : ''}
      </div>
    `).join('');

    this.querySelectorAll<HTMLElement>('.doc-item').forEach(item => {
      item.addEventListener('click', () => {
        const id = item.dataset['id'];
        if (id && this.onSelect) this.onSelect(id);
      });
    });
  }
}

customElements.define('document-list', DocumentList);
