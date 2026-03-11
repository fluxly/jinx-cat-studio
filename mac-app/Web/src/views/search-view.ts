import '../components/search-panel';
import type { SearchPanel } from '../components/search-panel';
import type { SearchResult } from '../bridge/bridge-client';
import type { AppShell } from '../components/app-shell';

export class SearchView extends HTMLElement {
  connectedCallback(): void {
    this.style.cssText = 'display:flex;flex:1;flex-direction:column;overflow:hidden;';
    this.render();
    this.bindEvents();
  }

  private render(): void {
    this.innerHTML = `<search-panel id="search-panel"></search-panel>`;
  }

  private bindEvents(): void {
    const panel = this.querySelector<SearchPanel>('#search-panel')!;
    panel.onResultSelect = (result: SearchResult) => {
      this.navigateToResult(result);
    };
  }

  private navigateToResult(result: SearchResult): void {
    const shell = document.querySelector<AppShell>('app-shell');
    if (!shell) return;

    if (result.type === 'document') {
      shell.switchView('documents');
      // Brief delay for view to mount
      setTimeout(() => {
        const event = new CustomEvent('document:open', { detail: { id: result.id }, bubbles: true });
        document.dispatchEvent(event);
      }, 100);
    } else if (result.type === 'asset') {
      shell.switchView('assets');
    }
  }
}

customElements.define('search-view', SearchView);
