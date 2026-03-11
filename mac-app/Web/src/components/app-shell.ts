import bridge from '../bridge/bridge-client';

export class AppShell extends HTMLElement {
  private currentView = 'documents';

  connectedCallback(): void {
    this.render();
    this.bindNavEvents();
    this.loadInitialData();
  }

  private render(): void {
    this.innerHTML = `
      <nav class="sidebar">
        <div class="sidebar-header">
          <div class="sidebar-title">Vault</div>
        </div>
        <div class="sidebar-nav">
          <div class="sidebar-section-label">Library</div>
          <div class="sidebar-item active" data-view="documents">
            <span class="icon">📄</span><span>Documents</span>
          </div>
          <div class="sidebar-item" data-view="assets">
            <span class="icon">🖼</span><span>Assets</span>
          </div>
          <div class="sidebar-section-label">Discover</div>
          <div class="sidebar-item" data-view="search">
            <span class="icon">🔍</span><span>Search</span>
          </div>
        </div>
        <div class="sidebar-footer">Vault by Jinx Cat Studio</div>
      </nav>
      <div class="main-content" id="main-content">
        <document-list-view></document-list-view>
      </div>
    `;
  }

  private bindNavEvents(): void {
    this.querySelectorAll<HTMLElement>('.sidebar-item').forEach(item => {
      item.addEventListener('click', () => {
        const view = item.dataset['view'];
        if (view) this.switchView(view);
      });
    });
  }

  switchView(view: string): void {
    this.currentView = view;
    this.querySelectorAll('.sidebar-item').forEach(item => {
      (item as HTMLElement).classList.toggle('active', (item as HTMLElement).dataset['view'] === view);
    });

    const main = this.querySelector('#main-content');
    if (!main) return;

    switch (view) {
      case 'documents': main.innerHTML = '<document-list-view></document-list-view>'; break;
      case 'assets':    main.innerHTML = '<asset-list-view></asset-list-view>'; break;
      case 'search':    main.innerHTML = '<search-view></search-view>'; break;
    }
  }

  private async loadInitialData(): Promise<void> {
    try {
      await Promise.all([bridge.tags.list(), bridge.categories.list()]);
    } catch (e) {
      console.error('Failed to load initial data:', e);
    }
  }
}

customElements.define('app-shell', AppShell);
