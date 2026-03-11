import type { Document, DocumentSummary, CreateDocumentPayload, UpdateDocumentPayload } from '../types/document';
import type { AssetSummary } from '../types/asset';
import type { Tag } from '../types/tag';
import type { Category } from '../types/category';

// Extend the global Window interface for WebKit bridge
declare global {
  interface Window {
    webkit: {
      messageHandlers: {
        bridge: {
          postMessage(message: BridgeCallMessage): void;
        };
      };
    };
    __pendingBridgeCalls: Map<string, PendingCall>;
    __bridgeCallback(id: string, jsonString: string): void;
    __bridgeCallbackB64(id: string, base64: string): void;
    app: BridgeClient;
  }
}

interface BridgeCallMessage {
  id: string;
  namespace: string;
  method: string;
  params: Record<string, unknown>;
}

interface BridgeSuccessResponse {
  id: string;
  success: true;
  data: unknown;
}

interface BridgeErrorResponse {
  id: string;
  success: false;
  error: { code: string; message: string };
}

type BridgeResponse = BridgeSuccessResponse | BridgeErrorResponse;

interface PendingCall {
  resolve: (value: unknown) => void;
  reject: (reason: unknown) => void;
}

export interface SearchResult {
  type: 'document' | 'asset';
  id: string;
  title: string;
  snippet: string;
  score: number;
}

export class BridgeClient {
  private readonly _pending: Map<string, PendingCall>;

  constructor() {
    this._pending = window.__pendingBridgeCalls;
  }

  call(namespace: string, method: string, params: Record<string, unknown> = {}): Promise<unknown> {
    return new Promise<unknown>((resolve, reject) => {
      const id = crypto.randomUUID();
      this._pending.set(id, { resolve, reject });
      try {
        window.webkit.messageHandlers.bridge.postMessage({ id, namespace, method, params });
      } catch (e) {
        this._pending.delete(id);
        reject({ code: 'BRIDGE_ERROR', message: (e as Error).message });
      }
    });
  }

  // ── Documents ────────────────────────────────────────────

  readonly documents = {
    list: (): Promise<DocumentSummary[]> =>
      this.call('documents', 'list') as Promise<DocumentSummary[]>,

    get: (id: string): Promise<Document> =>
      this.call('documents', 'get', { id }) as Promise<Document>,

    create: (payload: CreateDocumentPayload = {}): Promise<Document> =>
      this.call('documents', 'create', payload as Record<string, unknown>) as Promise<Document>,

    update: (id: string, payload: UpdateDocumentPayload): Promise<Document> =>
      this.call('documents', 'update', { id, ...payload } as Record<string, unknown>) as Promise<Document>,

    delete: (id: string): Promise<void> =>
      this.call('documents', 'delete', { id }) as Promise<void>,
  };

  // ── Assets ───────────────────────────────────────────────

  readonly assets = {
    list: (): Promise<AssetSummary[]> =>
      this.call('assets', 'list') as Promise<AssetSummary[]>,

    get: (id: string): Promise<AssetSummary> =>
      this.call('assets', 'get', { id }) as Promise<AssetSummary>,

    import: (): Promise<AssetSummary> =>
      this.call('assets', 'import') as Promise<AssetSummary>,

    update: (id: string, payload: Partial<AssetSummary>): Promise<AssetSummary> =>
      this.call('assets', 'update', { id, ...payload } as Record<string, unknown>) as Promise<AssetSummary>,

    delete: (id: string): Promise<void> =>
      this.call('assets', 'delete', { id }) as Promise<void>,
  };

  // ── Tags ─────────────────────────────────────────────────

  readonly tags = {
    list: (): Promise<Tag[]> =>
      this.call('tags', 'list') as Promise<Tag[]>,

    create: (name: string, color = '#808080'): Promise<Tag> =>
      this.call('tags', 'create', { name, color }) as Promise<Tag>,

    update: (id: string, payload: Partial<Omit<Tag, 'id' | 'createdAt'>>): Promise<Tag> =>
      this.call('tags', 'update', { id, ...payload } as Record<string, unknown>) as Promise<Tag>,

    delete: (id: string): Promise<void> =>
      this.call('tags', 'delete', { id }) as Promise<void>,

    assign: (tagId: string, documentId?: string, assetId?: string): Promise<void> => {
      const params: Record<string, unknown> = { tag_id: tagId };
      if (documentId) params['document_id'] = documentId;
      if (assetId) params['asset_id'] = assetId;
      return this.call('tags', 'assign', params) as Promise<void>;
    },

    unassign: (tagId: string, documentId?: string, assetId?: string): Promise<void> => {
      const params: Record<string, unknown> = { tag_id: tagId };
      if (documentId) params['document_id'] = documentId;
      if (assetId) params['asset_id'] = assetId;
      return this.call('tags', 'unassign', params) as Promise<void>;
    },
  };

  // ── Categories ───────────────────────────────────────────

  readonly categories = {
    list: (): Promise<Category[]> =>
      this.call('categories', 'list') as Promise<Category[]>,

    get: (id: string): Promise<Category> =>
      this.call('categories', 'get', { id }) as Promise<Category>,

    create: (name: string, parentId?: string): Promise<Category> =>
      this.call('categories', 'create', { name, parent_id: parentId }) as Promise<Category>,

    delete: (id: string): Promise<void> =>
      this.call('categories', 'delete', { id }) as Promise<void>,
  };

  // ── Search ───────────────────────────────────────────────

  readonly search = {
    query: (q: string, limit = 50): Promise<SearchResult[]> =>
      this.call('search', 'query', { q, limit }) as Promise<SearchResult[]>,
  };
}

// Initialize global bridge instance
window.__pendingBridgeCalls = new Map<string, PendingCall>();

window.__bridgeCallback = function (id: string, jsonString: string): void {
  const pending = window.__pendingBridgeCalls.get(id);
  if (!pending) return;
  window.__pendingBridgeCalls.delete(id);
  try {
    const response = JSON.parse(jsonString) as BridgeResponse;
    if (response.success) {
      pending.resolve(response.data);
    } else {
      pending.reject(response.error);
    }
  } catch (e) {
    pending.reject({ code: 'ENCODING_ERROR', message: `Failed to parse response: ${(e as Error).message}` });
  }
};

window.__bridgeCallbackB64 = function (id: string, base64: string): void {
  try {
    const jsonString = atob(base64);
    window.__bridgeCallback(id, jsonString);
  } catch (e) {
    const pending = window.__pendingBridgeCalls.get(id);
    if (pending) {
      window.__pendingBridgeCalls.delete(id);
      pending.reject({ code: 'ENCODING_ERROR', message: `Failed to decode base64 response: ${(e as Error).message}` });
    }
  }
};

const bridge = new BridgeClient();
window.app = bridge;

export default bridge;
