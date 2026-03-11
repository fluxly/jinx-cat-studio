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
  return '📎';
}

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
  } catch {
    return iso;
  }
}

export class AssetDetail extends HTMLElement {
  private asset: AssetSummary | null = null;

  onClose?: () => void;
  onDeleted?: (id: string) => void;

  connectedCallback(): void {
    this.style.cssText = `
      position: fixed; top: 0; right: 0; bottom: 0; width: 300px;
      background: var(--color-bg-secondary); border-left: 1px solid var(--color-border);
      padding: 20px; z-index: 100; overflow-y: auto;
      box-shadow: var(--shadow-lg);
      display: flex; flex-direction: column; gap: 16px;
    `;
  }

  show(asset: AssetSummary): void {
    this.asset = asset;
    this.renderDetail();
  }

  private renderDetail(): void {
    if (!this.asset) return;
    const asset = this.asset;
    const icon = fileIconForMime(asset.mimeType);
    const name = asset.original_filename || asset.filename;
    const size = formatBytes(asset.fileSize);

    this.innerHTML = `
      <div style="display:flex;align-items:center;justify-content:space-between;">
        <span style="font-size:15px;font-weight:600;">Asset Detail</span>
        <button class="btn btn-ghost btn-icon" id="close-detail">✕</button>
      </div>
      <div style="text-align:center;padding:20px;font-size:40px;">${icon}</div>
      <div>
        <div class="detail-section-label">Filename</div>
        <div style="font-size:13px;word-break:break-all;">${escapeHtml(name)}</div>
      </div>
      <div>
        <div class="detail-section-label">Type</div>
        <div style="font-size:13px;">${escapeHtml(asset.mimeType)}</div>
      </div>
      <div>
        <div class="detail-section-label">Size</div>
        <div style="font-size:13px;">${escapeHtml(size)}</div>
      </div>
      <div>
        <div class="detail-section-label">Added</div>
        <div style="font-size:13px;">${formatDate(asset.createdAt)}</div>
      </div>
      ${asset.tags?.length ? `
        <div>
          <div class="detail-section-label">Tags</div>
          <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:4px;">
            ${asset.tags.map(t => `
              <span class="tag-chip">
                <span class="tag-dot" style="background:${escapeHtml(t.color)}"></span>
                ${escapeHtml(t.name)}
              </span>
            `).join('')}
          </div>
        </div>
      ` : ''}
      <button class="btn btn-danger" id="btn-delete-asset" style="width:100%;justify-content:center;">
        🗑 Delete Asset
      </button>
    `;

    this.querySelector('#close-detail')!.addEventListener('click', () => {
      if (this.onClose) this.onClose();
    });

    this.querySelector('#btn-delete-asset')!.addEventListener('click', async () => {
      if (!confirm('Delete this asset? This cannot be undone.')) return;
      try {
        await bridge.assets.delete(asset.id);
        if (this.onDeleted) this.onDeleted(asset.id);
      } catch {
        console.error('Failed to delete asset');
      }
    });
  }
}

customElements.define('asset-detail', AssetDetail);
