/**
 * Component tests for the Vault web UI.
 *
 * These tests are designed to run in a browser-like environment (e.g. jsdom via Jest
 * or Vitest). They mock the WebKit bridge and verify component behavior.
 *
 * To run: add a test runner (e.g. vitest) to the Web/ package and point it at
 * Tests/WebTests/component-tests.ts.
 */

// ─── Mock Bridge ──────────────────────────────────────────────────────────────

interface MockBridgeResponse {
  success: boolean;
  data?: unknown;
  error?: { code: string; message: string };
}

type MockHandler = (params: Record<string, unknown>) => MockBridgeResponse;

const mockHandlers = new Map<string, MockHandler>();

function registerMock(namespace: string, method: string, handler: MockHandler): void {
  mockHandlers.set(`${namespace}.${method}`, handler);
}

function setupMockBridge(): void {
  (window as Window & { __pendingBridgeCalls: Map<string, { resolve: (v: unknown) => void; reject: (r: unknown) => void }> })
    .__pendingBridgeCalls = new Map();

  (window as Window & { webkit: { messageHandlers: { bridge: { postMessage: (msg: unknown) => void } } } }).webkit = {
    messageHandlers: {
      bridge: {
        postMessage(message: unknown): void {
          const msg = message as { id: string; namespace: string; method: string; params: Record<string, unknown> };
          const key = `${msg.namespace}.${msg.method}`;
          const handler = mockHandlers.get(key);

          setTimeout(() => {
            const pending = (window as Window & { __pendingBridgeCalls: Map<string, { resolve: (v: unknown) => void; reject: (r: unknown) => void }> })
              .__pendingBridgeCalls.get(msg.id);
            if (!pending) return;
            (window as Window & { __pendingBridgeCalls: Map<string, { resolve: (v: unknown) => void; reject: (r: unknown) => void }> })
              .__pendingBridgeCalls.delete(msg.id);

            if (handler) {
              const result = handler(msg.params);
              if (result.success) pending.resolve(result.data);
              else pending.reject(result.error);
            } else {
              pending.reject({ code: 'UNKNOWN_METHOD', message: `No mock for ${key}` });
            }
          }, 0);
        },
      },
    },
  };
}

// ─── Test Suite (pseudo-test framework compatible with Jest/Vitest) ────────────

declare function describe(name: string, fn: () => void): void;
declare function it(name: string, fn: () => Promise<void> | void): void;
declare function expect(value: unknown): {
  toBe(expected: unknown): void;
  toEqual(expected: unknown): void;
  toBeTruthy(): void;
  toBeFalsy(): void;
  toHaveLength(n: number): void;
  toContain(item: unknown): void;
};
declare function beforeEach(fn: () => void): void;

// ─── Mock Data ───────────────────────────────────────────────────────────────

const mockDocuments = [
  {
    id: 'doc-1',
    title: 'First Document',
    body_snippet: 'This is the first document',
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-02T00:00:00Z',
    tags: [],
    categories: [],
  },
  {
    id: 'doc-2',
    title: 'Second Document',
    body_snippet: 'Another document',
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-03T00:00:00Z',
    tags: [{ id: 'tag-1', name: 'Work', color: '#ff0000', createdAt: '2024-01-01T00:00:00Z' }],
    categories: [],
  },
];

const mockDocument = {
  id: 'doc-1',
  title: 'First Document',
  body: 'This is the full body text',
  body_snippet: 'This is the first document',
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-02T00:00:00Z',
  tags: [],
  categories: [],
  assets: [],
};

const mockAssets = [
  {
    id: 'asset-1',
    filename: 'abc123.png',
    original_filename: 'photo.png',
    mimeType: 'image/png',
    fileSize: 102400,
    sha256: 'abc123',
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
    tags: [],
    categories: [],
  },
];

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('BridgeClient', () => {
  beforeEach(() => {
    setupMockBridge();
    registerMock('documents', 'list', () => ({ success: true, data: mockDocuments }));
    registerMock('documents', 'get', (params) => ({
      success: true,
      data: params['id'] === 'doc-1' ? mockDocument : null,
    }));
    registerMock('documents', 'create', () => ({ success: true, data: mockDocument }));
    registerMock('documents', 'delete', () => ({ success: true, data: true }));
    registerMock('assets', 'list', () => ({ success: true, data: mockAssets }));
    registerMock('tags', 'list', () => ({ success: true, data: [] }));
    registerMock('categories', 'list', () => ({ success: true, data: [] }));
    registerMock('search', 'query', (params) => ({
      success: true,
      data: (params['q'] as string) ? [
        { type: 'document', id: 'doc-1', title: 'First Document', snippet: '...content...', score: -1.5 },
      ] : [],
    }));
  });

  it('resolves document list successfully', async () => {
    // Dynamic import to get bridge after mock is set up
    const { BridgeClient } = await import('../../Web/src/bridge/bridge-client');
    const client = new BridgeClient();
    const docs = await client.documents.list();
    expect(docs).toHaveLength(2);
    expect(docs[0]!.id).toBe('doc-1');
    expect(docs[1]!.title).toBe('Second Document');
  });

  it('resolves document get by id', async () => {
    const { BridgeClient } = await import('../../Web/src/bridge/bridge-client');
    const client = new BridgeClient();
    const doc = await client.documents.get('doc-1');
    expect(doc.title).toBe('First Document');
    expect(doc.body).toBe('This is the full body text');
  });

  it('rejects with error when bridge returns failure', async () => {
    registerMock('documents', 'get', () => ({
      success: false,
      error: { code: 'NOT_FOUND', message: 'Document not found' },
    }));
    const { BridgeClient } = await import('../../Web/src/bridge/bridge-client');
    const client = new BridgeClient();
    let caught: unknown;
    try {
      await client.documents.get('missing-id');
    } catch (e) {
      caught = e;
    }
    expect((caught as { code: string }).code).toBe('NOT_FOUND');
  });

  it('performs search and returns results', async () => {
    const { BridgeClient } = await import('../../Web/src/bridge/bridge-client');
    const client = new BridgeClient();
    const results = await client.search.query('first');
    expect(results).toHaveLength(1);
    expect(results[0]!.type).toBe('document');
  });

  it('returns empty array for empty search query', async () => {
    const { BridgeClient } = await import('../../Web/src/bridge/bridge-client');
    const client = new BridgeClient();
    const results = await client.search.query('');
    expect(results).toHaveLength(0);
  });
});

describe('Document list rendering', () => {
  beforeEach(() => {
    setupMockBridge();
    registerMock('documents', 'list', () => ({ success: true, data: mockDocuments }));
    registerMock('tags', 'list', () => ({ success: true, data: [] }));
    registerMock('categories', 'list', () => ({ success: true, data: [] }));
  });

  it('renders document items', async () => {
    const listEl = document.createElement('document-list') as HTMLElement;
    document.body.appendChild(listEl);

    // Wait for async load
    await new Promise(resolve => setTimeout(resolve, 50));

    const items = listEl.querySelectorAll('.doc-item');
    expect(items.length).toBe(2);
    document.body.removeChild(listEl);
  });
});
