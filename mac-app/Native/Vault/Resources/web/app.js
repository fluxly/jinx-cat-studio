// ============================================================
// Vault — app.js
// Complete vanilla JavaScript UI for the Vault document manager.
// No build step required. Runs as an ES module in WKWebView.
// ============================================================

'use strict';

// ============================================================
// BridgeClient
// ============================================================
class BridgeClient {
  constructor() {
    this._pending = window.__pendingBridgeCalls;

    // Namespaced convenience APIs
    this.documents = {
      list: () => this.call('documents', 'list'),
      get: (id) => this.call('documents', 'get', { id }),
      create: (payload) => this.call('documents', 'create', payload),
      update: (id, payload) => this.call('documents', 'update', { id, ...payload }),
      delete: (id) => this.call('documents', 'delete', { id }),
    };

    this.assets = {
      list: () => this.call('assets', 'list'),
      get: (id) => this.call('assets', 'get', { id }),
      import: () => this.call('assets', 'import'),
      update: (id, payload) => this.call('assets', 'update', { id, ...payload }),
      delete: (id) => this.call('assets', 'delete', { id }),
    };

    this.tags = {
      list: () => this.call('tags', 'list'),
      create: (name, color) => this.call('tags', 'create', { name, color }),
      update: (id, payload) => this.call('tags', 'update', { id, ...payload }),
      delete: (id) => this.call('tags', 'delete', { id }),
      assign: (tagId, documentId, assetId) => {
        const params = { tag_id: tagId };
        if (documentId) params.document_id = documentId;
        if (assetId) params.asset_id = assetId;
        return this.call('tags', 'assign', params);
      },
      unassign: (tagId, documentId, assetId) => {
        const params = { tag_id: tagId };
        if (documentId) params.document_id = documentId;
        if (assetId) params.asset_id = assetId;
        return this.call('tags', 'unassign', params);
      },
    };

    this.categories = {
      list: () => this.call('categories', 'list'),
      get: (id) => this.call('categories', 'get', { id }),
      create: (name, parentId) => this.call('categories', 'create', { name, parent_id: parentId }),
      delete: (id) => this.call('categories', 'delete', { id }),
    };

    this.search = {
      query: (q, limit = 50) => this.call('search', 'query', { q, limit }),
    };
  }

  call(namespace, method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = crypto.randomUUID();
      this._pending.set(id, { resolve, reject });
      try {
        window.webkit.messageHandlers.bridge.postMessage({ id, namespace, method, params });
      } catch (e) {
        this._pending.delete(id);
        reject({ code: 'BRIDGE_ERROR', message: e.message });
      }
    });
  }
}

// Singleton bridge instance
const bridge = new BridgeClient();
window.app = bridge;

// ============================================================
// Toast notifications
// ============================================================
class ToastManager {
  constructor() {
    this.container = document.createElement('div');
    this.container.className = 'toast-container';
    document.body.appendChild(this.container);
  }

  show(message, type = 'info', duration = 3000) {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    this.container.appendChild(toast);
    setTimeout(() => toast.remove(), duration);
  }

  success(msg) { this.show(msg, 'success'); }
  error(msg) { this.show(msg, 'error'); }
  info(msg) { this.show(msg, 'info'); }
}

const toast = new ToastManager();

// ============================================================
// App State
// ============================================================
const state = {
  currentView: 'documents',
  selectedDocumentId: null,
  selectedAssetId: null,
  documents: [],
  assets: [],
  tags: [],
  categories: [],
  searchResults: [],
  loading: false,
};

// Simple event emitter for state updates
const events = new EventTarget();
function emit(event, detail) { events.dispatchEvent(new CustomEvent(event, { detail })); }

// ============================================================
// Helpers
// ============================================================
function formatDate(isoString) {
  if (!isoString) return '';
  try {
    const d = new Date(isoString);
    return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
  } catch { return isoString; }
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function fileIconForMime(mime) {
  if (mime.startsWith('image/')) return '🖼';
  if (mime.startsWith('video/')) return '🎬';
  if (mime.startsWith('audio/')) return '🎵';
  if (mime === 'application/pdf') return '📄';
  if (mime.startsWith('text/')) return '📝';
  if (mime === 'application/zip') return '🗜';
  return '📎';
}

function isImageMime(mime) {
  return mime.startsWith('image/') && mime !== 'image/svg+xml';
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function debounce(fn, delay) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

// ============================================================
// app-shell Web Component
// ============================================================
class AppShell extends HTMLElement {
  connectedCallback() {
    this.render();
    this._bindNavEvents();
    this._listenToState();
    this._loadInitialData();
  }

  render() {
    this.innerHTML = `
      <nav class="sidebar">
        <div class="sidebar-header">
          <div class="sidebar-title">Vault</div>
        </div>
        <div class="sidebar-nav">
          <div class="sidebar-section-label">Library</div>
          <div class="sidebar-item active" data-view="documents">
            <span class="icon">📄</span>
            <span>Documents</span>
          </div>
          <div class="sidebar-item" data-view="assets">
            <span class="icon">🖼</span>
            <span>Assets</span>
          </div>
          <div class="sidebar-section-label">Discover</div>
          <div class="sidebar-item" data-view="search">
            <span class="icon">🔍</span>
            <span>Search</span>
          </div>
        </div>
        <div class="sidebar-footer">
          Vault by Jinx Cat Studio
        </div>
      </nav>
      <div class="main-content" id="main-content">
        <document-list-view></document-list-view>
      </div>
    `;
  }

  _bindNavEvents() {
    this.querySelectorAll('.sidebar-item').forEach(item => {
      item.addEventListener('click', () => {
        const view = item.dataset.view;
        this._switchView(view);
      });
    });
  }

  _switchView(view) {
    state.currentView = view;

    // Update nav active state
    this.querySelectorAll('.sidebar-item').forEach(item => {
      item.classList.toggle('active', item.dataset.view === view);
    });

    const main = this.querySelector('#main-content');
    if (!main) return;

    switch (view) {
      case 'documents':
        main.innerHTML = '<document-list-view></document-list-view>';
        break;
      case 'assets':
        main.innerHTML = '<asset-list-view></asset-list-view>';
        break;
      case 'search':
        main.innerHTML = '<search-view></search-view>';
        break;
    }
  }

  _listenToState() {
    events.addEventListener('view:switch', (e) => {
      this._switchView(e.detail.view);
    });
  }

  async _loadInitialData() {
    try {
      state.tags = await bridge.tags.list();
      state.categories = await bridge.categories.list();
    } catch (e) {
      console.error('Failed to load initial data:', e);
    }
  }
}

customElements.define('app-shell', AppShell);

// ============================================================
// document-list-view Web Component
// ============================================================
class DocumentListView extends HTMLElement {
  constructor() {
    super();
    this._documents = [];
    this._selectedId = null;
    this._autosaveTimer = null;
  }

  connectedCallback() {
    this.render();
    this._loadDocuments();
  }

  render() {
    this.style.cssText = 'display:flex;flex:1;overflow:hidden;';
    this.innerHTML = `
      <div class="list-panel">
        <div class="list-panel-header">
          <span class="list-panel-title">Documents</span>
          <button class="btn btn-primary" id="btn-new-doc">+ New</button>
        </div>
        <div class="list-panel-body" id="doc-list-body">
          <div class="empty-state">
            <div class="loading-spinner"></div>
          </div>
        </div>
      </div>
      <div class="editor-panel" id="editor-area">
        <div class="editor-empty-state">
          <div class="empty-icon">📄</div>
          <p>Select a document or create a new one</p>
        </div>
      </div>
    `;
    this.querySelector('#btn-new-doc').addEventListener('click', () => this._createDocument());
  }

  async _loadDocuments() {
    try {
      this._documents = await bridge.documents.list();
      state.documents = this._documents;
      this._renderList();
    } catch (e) {
      console.error('Failed to load documents:', e);
      this.querySelector('#doc-list-body').innerHTML = `
        <div class="empty-state"><p class="text-muted">Failed to load documents</p></div>
      `;
    }
  }

  _renderList() {
    const body = this.querySelector('#doc-list-body');
    if (!this._documents.length) {
      body.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">📝</div>
          <h3>No Documents</h3>
          <p>Create your first document to get started</p>
        </div>
      `;
      return;
    }

    body.innerHTML = this._documents.map(doc => `
      <div class="doc-item ${doc.id === this._selectedId ? 'selected' : ''}"
           data-id="${escapeHtml(doc.id)}">
        <div class="doc-title">${escapeHtml(doc.title || 'Untitled')}</div>
        <div class="doc-snippet">${escapeHtml(doc.body_snippet || '')}</div>
        <div class="doc-meta">${formatDate(doc.updatedAt || doc.updated_at)}</div>
        ${doc.tags && doc.tags.length ? `
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

    body.querySelectorAll('.doc-item').forEach(item => {
      item.addEventListener('click', () => this._selectDocument(item.dataset.id));
    });
  }

  async _selectDocument(id) {
    this._selectedId = id;
    state.selectedDocumentId = id;
    this._renderList();
    await this._loadDocumentEditor(id);
  }

  async _loadDocumentEditor(id) {
    const editorArea = this.querySelector('#editor-area');
    editorArea.innerHTML = `<div class="editor-empty-state"><div class="loading-spinner"></div></div>`;

    try {
      const doc = await bridge.documents.get(id);
      this._renderEditor(doc);
    } catch (e) {
      editorArea.innerHTML = `<div class="editor-empty-state"><p class="text-muted">Failed to load document</p></div>`;
    }
  }

  _renderEditor(doc) {
    const editorArea = this.querySelector('#editor-area');
    editorArea.innerHTML = `
      <div class="editor-toolbar">
        <input
          class="editor-title-input"
          id="doc-title"
          type="text"
          placeholder="Untitled"
          value="${escapeHtml(doc.title || '')}"
        />
        <button class="btn btn-ghost btn-icon" id="btn-delete-doc" title="Delete document">🗑</button>
      </div>
      <div class="editor-body">
        <textarea
          class="editor-textarea"
          id="doc-body"
          placeholder="Start writing..."
        >${escapeHtml(doc.body || '')}</textarea>
      </div>
    `;

    const titleInput = editorArea.querySelector('#doc-title');
    const bodyTextarea = editorArea.querySelector('#doc-body');
    const deleteBtn = editorArea.querySelector('#btn-delete-doc');

    const saveDoc = debounce(async () => {
      try {
        await bridge.documents.update(doc.id, {
          title: titleInput.value,
          body: bodyTextarea.value,
        });
        // Refresh list
        this._documents = await bridge.documents.list();
        state.documents = this._documents;
        this._renderList();
      } catch (e) {
        toast.error('Failed to save document');
      }
    }, 800);

    titleInput.addEventListener('input', saveDoc);
    bodyTextarea.addEventListener('input', saveDoc);

    deleteBtn.addEventListener('click', async () => {
      if (!confirm('Delete this document? This cannot be undone.')) return;
      try {
        await bridge.documents.delete(doc.id);
        toast.success('Document deleted');
        this._selectedId = null;
        state.selectedDocumentId = null;
        await this._loadDocuments();
        editorArea.innerHTML = `
          <div class="editor-empty-state">
            <div class="empty-icon">📄</div>
            <p>Select a document or create a new one</p>
          </div>
        `;
      } catch (e) {
        toast.error('Failed to delete document');
      }
    });
  }

  async _createDocument() {
    try {
      const doc = await bridge.documents.create({ title: '', body: '' });
      toast.success('Document created');
      await this._loadDocuments();
      await this._selectDocument(doc.id);
    } catch (e) {
      toast.error('Failed to create document');
    }
  }
}

customElements.define('document-list-view', DocumentListView);

// ============================================================
// asset-list-view Web Component
// ============================================================
class AssetListView extends HTMLElement {
  constructor() {
    super();
    this._assets = [];
    this._selectedId = null;
  }

  connectedCallback() {
    this.style.cssText = 'display:flex;flex:1;flex-direction:column;overflow:hidden;';
    this.render();
    this._loadAssets();
  }

  render() {
    this.innerHTML = `
      <div class="assets-toolbar">
        <span style="font-size:15px;font-weight:600;flex:1;">Assets</span>
        <button class="btn btn-primary" id="btn-import">⬆ Import File</button>
      </div>
      <div class="assets-grid" id="assets-grid">
        <div style="grid-column:1/-1" class="empty-state">
          <div class="loading-spinner"></div>
        </div>
      </div>
    `;
    this.querySelector('#btn-import').addEventListener('click', () => this._importAsset());
  }

  async _loadAssets() {
    try {
      this._assets = await bridge.assets.list();
      state.assets = this._assets;
      this._renderGrid();
    } catch (e) {
      console.error('Failed to load assets:', e);
      this.querySelector('#assets-grid').innerHTML = `
        <div style="grid-column:1/-1" class="empty-state">
          <p class="text-muted">Failed to load assets</p>
        </div>
      `;
    }
  }

  _renderGrid() {
    const grid = this.querySelector('#assets-grid');
    if (!this._assets.length) {
      grid.innerHTML = `
        <div style="grid-column:1/-1" class="empty-state">
          <div class="empty-icon">🖼</div>
          <h3>No Assets</h3>
          <p>Import files to add them to your vault</p>
        </div>
      `;
      return;
    }

    grid.innerHTML = this._assets.map(asset => {
      const isImage = isImageMime(asset.mimeType || asset.mime_type || '');
      const mimeType = asset.mimeType || asset.mime_type || '';
      const icon = fileIconForMime(mimeType);
      const name = asset.original_filename || asset.originalFilename || asset.filename;
      const size = formatBytes(asset.fileSize || asset.file_size || 0);

      return `
        <div class="asset-card ${asset.id === this._selectedId ? 'selected' : ''}"
             data-id="${escapeHtml(asset.id)}">
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

    grid.querySelectorAll('.asset-card').forEach(card => {
      card.addEventListener('click', () => {
        this._selectedId = card.dataset.id;
        this._renderGrid();
        this._showAssetDetail(card.dataset.id);
      });
    });
  }

  async _showAssetDetail(id) {
    const asset = this._assets.find(a => a.id === id);
    if (!asset) return;

    const mimeType = asset.mimeType || asset.mime_type || '';
    const name = asset.original_filename || asset.originalFilename || asset.filename;
    const size = formatBytes(asset.fileSize || asset.file_size || 0);

    // Show a simple detail panel — append to main content or use modal
    let detail = this.querySelector('#asset-detail-overlay');
    if (!detail) {
      detail = document.createElement('div');
      detail.id = 'asset-detail-overlay';
      detail.style.cssText = `
        position: fixed; top: 0; right: 0; bottom: 0; width: 300px;
        background: var(--color-bg-secondary); border-left: 1px solid var(--color-border);
        padding: 20px; z-index: 100; overflow-y: auto;
        box-shadow: var(--shadow-lg);
        display: flex; flex-direction: column; gap: 16px;
      `;
      document.body.appendChild(detail);
    }

    detail.innerHTML = `
      <div style="display:flex;align-items:center;justify-content:space-between;">
        <span style="font-size:15px;font-weight:600;">Asset Detail</span>
        <button class="btn btn-ghost btn-icon" id="close-detail">✕</button>
      </div>
      <div style="text-align:center;padding:20px;font-size:40px;">${fileIconForMime(mimeType)}</div>
      <div>
        <div class="detail-section-label">Filename</div>
        <div style="font-size:13px;word-break:break-all;">${escapeHtml(name)}</div>
      </div>
      <div>
        <div class="detail-section-label">Type</div>
        <div style="font-size:13px;">${escapeHtml(mimeType)}</div>
      </div>
      <div>
        <div class="detail-section-label">Size</div>
        <div style="font-size:13px;">${escapeHtml(size)}</div>
      </div>
      <div>
        <div class="detail-section-label">Added</div>
        <div style="font-size:13px;">${formatDate(asset.createdAt || asset.created_at)}</div>
      </div>
      ${asset.tags && asset.tags.length ? `
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

    detail.querySelector('#close-detail').addEventListener('click', () => {
      detail.remove();
      this._selectedId = null;
      this._renderGrid();
    });

    detail.querySelector('#btn-delete-asset').addEventListener('click', async () => {
      if (!confirm('Delete this asset? This cannot be undone.')) return;
      try {
        await bridge.assets.delete(id);
        toast.success('Asset deleted');
        detail.remove();
        this._selectedId = null;
        await this._loadAssets();
      } catch (e) {
        toast.error('Failed to delete asset');
      }
    });
  }

  async _importAsset() {
    try {
      const asset = await bridge.assets.import();
      toast.success(`Imported: ${asset.original_filename || asset.originalFilename}`);
      await this._loadAssets();
    } catch (e) {
      if (e.code === 'USER_CANCELLED') return;
      toast.error('Failed to import asset');
      console.error(e);
    }
  }
}

customElements.define('asset-list-view', AssetListView);

// ============================================================
// search-view Web Component
// ============================================================
class SearchView extends HTMLElement {
  constructor() {
    super();
    this._results = [];
  }

  connectedCallback() {
    this.style.cssText = 'display:flex;flex:1;flex-direction:column;overflow:hidden;';
    this.render();
  }

  render() {
    this.innerHTML = `
      <div class="search-header">
        <div class="search-input-wrap">
          <span class="search-icon">🔍</span>
          <input
            class="search-input"
            id="search-input"
            type="text"
            placeholder="Search documents and assets..."
            autofocus
          />
        </div>
      </div>
      <div class="search-results" id="search-results">
        <div class="search-empty-state">
          <div style="font-size:32px;opacity:0.4;">🔍</div>
          <p>Type to search across all documents and assets</p>
        </div>
      </div>
    `;

    const input = this.querySelector('#search-input');
    const doSearch = debounce(async (query) => {
      if (!query.trim()) {
        this._renderEmptyState();
        return;
      }
      this._renderLoading();
      try {
        this._results = await bridge.search.query(query);
        this._renderResults(query);
      } catch (e) {
        this._renderError();
      }
    }, 300);

    input.addEventListener('input', (e) => doSearch(e.target.value));
    input.focus();
  }

  _renderEmptyState() {
    this.querySelector('#search-results').innerHTML = `
      <div class="search-empty-state">
        <div style="font-size:32px;opacity:0.4;">🔍</div>
        <p>Type to search across all documents and assets</p>
      </div>
    `;
  }

  _renderLoading() {
    this.querySelector('#search-results').innerHTML = `
      <div class="search-empty-state">
        <div class="loading-spinner"></div>
      </div>
    `;
  }

  _renderError() {
    this.querySelector('#search-results').innerHTML = `
      <div class="search-empty-state">
        <p class="text-muted">Search failed. Please try again.</p>
      </div>
    `;
  }

  _renderResults(query) {
    const container = this.querySelector('#search-results');
    if (!this._results.length) {
      container.innerHTML = `
        <div class="search-empty-state">
          <p class="text-muted">No results for "<strong>${escapeHtml(query)}</strong>"</p>
        </div>
      `;
      return;
    }

    container.innerHTML = this._results.map(r => `
      <div class="search-result-item" data-type="${escapeHtml(r.type)}" data-id="${escapeHtml(r.id)}">
        <div>
          <span class="search-result-type ${escapeHtml(r.type)}">${escapeHtml(r.type)}</span>
        </div>
        <div class="search-result-title">${escapeHtml(r.title)}</div>
        ${r.snippet ? `<div class="search-result-snippet">${escapeHtml(r.snippet)}</div>` : ''}
      </div>
    `).join('');

    container.querySelectorAll('.search-result-item').forEach(item => {
      item.addEventListener('click', () => {
        if (item.dataset.type === 'document') {
          emit('view:switch', { view: 'documents' });
          // Small delay to let view render
          setTimeout(() => {
            state.selectedDocumentId = item.dataset.id;
            events.dispatchEvent(new CustomEvent('document:open', { detail: { id: item.dataset.id } }));
          }, 100);
        } else if (item.dataset.type === 'asset') {
          emit('view:switch', { view: 'assets' });
        }
      });
    });
  }
}

customElements.define('search-view', SearchView);

// ============================================================
// Boot
// ============================================================
document.addEventListener('DOMContentLoaded', () => {
  // The app-shell is already in the HTML; just make sure it's connected.
  const shell = document.getElementById('app');
  if (shell && !shell.isConnected) {
    document.body.appendChild(shell);
  }
});
