import bridge from '../bridge/bridge-client';
import type { SearchResult } from '../bridge/bridge-client';

function escapeHtml(str: string): string {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function debounce<T extends (...args: unknown[]) => unknown>(fn: T, delay: number): (...args: Parameters<T>) => void {
  let timer: ReturnType<typeof setTimeout>;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

export class SearchPanel extends HTMLElement {
  private results: SearchResult[] = [];

  onResultSelect?: (result: SearchResult) => void;

  connectedCallback(): void {
    this.style.cssText = 'display:flex;flex-direction:column;flex:1;overflow:hidden;';
    this.render();
  }

  private render(): void {
    this.innerHTML = `
      <div class="search-header">
        <div class="search-input-wrap">
          <span class="search-icon">🔍</span>
          <input class="search-input" id="search-input" type="text"
                 placeholder="Search documents and assets..." autofocus />
        </div>
      </div>
      <div class="search-results" id="search-results">
        <div class="search-empty-state">
          <div style="font-size:32px;opacity:0.4;">🔍</div>
          <p>Type to search across all documents and assets</p>
        </div>
      </div>
    `;

    const input = this.querySelector<HTMLInputElement>('#search-input')!;
    const doSearch = debounce(async (query: unknown) => {
      const q = query as string;
      if (!q.trim()) {
        this.renderEmptyState();
        return;
      }
      this.renderLoading();
      try {
        this.results = await bridge.search.query(q);
        this.renderResults(q);
      } catch {
        this.renderError();
      }
    }, 300);

    input.addEventListener('input', (e) => doSearch((e.target as HTMLInputElement).value));
    input.focus();
  }

  private renderEmptyState(): void {
    const container = this.querySelector('#search-results')!;
    container.innerHTML = `
      <div class="search-empty-state">
        <div style="font-size:32px;opacity:0.4;">🔍</div>
        <p>Type to search across all documents and assets</p>
      </div>
    `;
  }

  private renderLoading(): void {
    const container = this.querySelector('#search-results')!;
    container.innerHTML = '<div class="search-empty-state"><div class="loading-spinner"></div></div>';
  }

  private renderError(): void {
    const container = this.querySelector('#search-results')!;
    container.innerHTML = '<div class="search-empty-state"><p class="text-muted">Search failed. Please try again.</p></div>';
  }

  private renderResults(query: string): void {
    const container = this.querySelector('#search-results')!;
    if (!this.results.length) {
      container.innerHTML = `
        <div class="search-empty-state">
          <p class="text-muted">No results for "<strong>${escapeHtml(query)}</strong>"</p>
        </div>
      `;
      return;
    }

    container.innerHTML = this.results.map(r => `
      <div class="search-result-item" data-type="${escapeHtml(r.type)}" data-id="${escapeHtml(r.id)}">
        <div><span class="search-result-type ${escapeHtml(r.type)}">${escapeHtml(r.type)}</span></div>
        <div class="search-result-title">${escapeHtml(r.title)}</div>
        ${r.snippet ? `<div class="search-result-snippet">${escapeHtml(r.snippet)}</div>` : ''}
      </div>
    `).join('');

    container.querySelectorAll<HTMLElement>('.search-result-item').forEach(item => {
      item.addEventListener('click', () => {
        const type = item.dataset['type'] as 'document' | 'asset';
        const id = item.dataset['id']!;
        const result = this.results.find(r => r.id === id && r.type === type);
        if (result && this.onResultSelect) this.onResultSelect(result);
      });
    });
  }
}

customElements.define('search-panel', SearchPanel);
