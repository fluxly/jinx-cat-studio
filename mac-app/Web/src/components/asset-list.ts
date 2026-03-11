import bridge from '../bridge/bridge-client';
import type { AssetSummary } from '../types/asset';

function escapeHtml(str: string): string {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function fileIconForMime(mime: string): string {
  if (mime.startsWith('image/')) return '🖼';
  if (mime.startsWith('video/')) return '🎬';
  if (mime.startsWith('audio/')) return '🎵';
  if (mime === 'application/pdf') return '📄';
  if (mime.startsWith('text/')) return '📝';
  if (mime === 'application/zip') return '🗜';
  return '📎';
}

export class AssetList extends HTMLElement {
  private assets: AssetSummary[] = [];
  private selectedId: string | null = null;

  onSelect?: (asset: AssetSummary) => void;
  onImported?: (asset: AssetSummary) => void;

  connectedCallback(): void {
    this.style.cssText = 'display:flex;flex-direction:column;flex:1;overflow:hidden;';
    this.render();
    this.loadAssets();
  }

  private render(): void {
    this.innerHTML = `
      <div class="assets-toolbar">
        <span style="font-size:15px;font-weight:600;flex:1;">Assets</span>
        <button class="btn btn-primary" id="btn-import">⬆ Import File</button>
      </div>
      <div class="assets-grid" id="assets-grid">
        <div style="grid-column:1/-1" class="empty-state"><div class="loading-spinner"></div></div>
      </div>
    `;
    this.querySelector('#btn-import')!.addEventListener('click', () => this.importAsset());
  }

  async loadAssets(): Promise<void> {
    try {
      this.assets = await bridge.assets.list();
      this.renderGrid();
    } catch {
      const grid = this.querySelector('#assets-grid');
      if (grid) grid.innerHTML = '<div style="grid-column:1/-1" class="empty-state"><p class="text-muted">Failed to load assets</p></div>';
    }
  }

  private renderGrid(): void {
    const grid = this.querySelector('#assets-grid');
    if (!grid) return;

    if (!this.assets.length) {
      grid.innerHTML = `
        <div style="grid-column:1/-1" class="empty-state">
          <div class="empty-icon">🖼</div>
          <h3>No Assets</h3>
          <p>Import files to add them to your vault</p>
        </div>
      `;
      return;
    }

    grid.innerHTML = this.assets.map(asset => {
      const icon = fileIconForMime(asset.mimeType);
      const name = asset.original_filename || asset.filename;
      const size = formatBytes(asset.fileSize);
      return `
        <div class="asset-card ${asset.id === this.selectedId ? 'selected' : ''}" data-id="${escapeHtml(asset.id)}">
          <div class="asset-preview">
            <span class="file-icon">${icon}</span>
          </div>
          <div class="asset-info">
            <div class="asset-name" title="${escapeHtml(name)}">${escapeHtml(name)}</div>
            <div class="asset-size">${escapeHtml(size)}</div>
          </div>
        </div>
      `;
    }).join('');

    grid.querySelectorAll<HTMLElement>('.asset-card').forEach(card => {
      card.addEventListener('click', () => {
        const id = card.dataset['id'];
        const asset = this.assets.find(a => a.id === id);
        if (asset) {
          this.selectedId = id ?? null;
          this.renderGrid();
          if (this.onSelect) this.onSelect(asset);
        }
      });
    });
  }

  private async importAsset(): Promise<void> {
    try {
      const asset = await bridge.assets.import();
      if (this.onImported) this.onImported(asset);
      await this.loadAssets();
    } catch (e: unknown) {
      const err = e as { code?: string };
      if (err.code !== 'USER_CANCELLED') {
        console.error('Failed to import asset:', e);
      }
    }
  }
}

customElements.define('asset-list', AssetList);
