/**
 * bridge-client-tests.ts
 * Vitest unit tests for BridgeClient
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// ── Mock window.webkit before importing bridge-client ──────────────────────
// We mock the webkit message handler so postMessage doesn't throw
const mockPostMessage = vi.fn();
Object.defineProperty(globalThis, 'window', {
  value: {
    webkit: {
      messageHandlers: {
        bridge: { postMessage: mockPostMessage },
      },
    },
    nativeBridge: undefined,
  },
  writable: true,
});

// Import after setting up window mock
import { BridgeClient, BridgeError } from '../../Web/src/bridge/bridge-client.js';

// Helper: instantiate a fresh BridgeClient per test to avoid shared state
function makeBridge(): BridgeClient {
  // BridgeClient constructor sets window.nativeBridge
  return new (BridgeClient as unknown as new () => BridgeClient)();
}

// ── Tests ──────────────────────────────────────────────────────────────────

describe('BridgeClient', () => {

  beforeEach(() => {
    vi.useFakeTimers();
    mockPostMessage.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // ── ID Generation ────────────────────────────────────────────────────────

  it('generates unique IDs for each call', async () => {
    const bridge = makeBridge();
    const ids: string[] = [];

    // Start two calls without resolving them
    bridge.call('meta.getOptions').catch(() => {});
    bridge.call('meta.getOptions').catch(() => {});

    // Capture the JSON strings sent to postMessage
    const call0 = JSON.parse(mockPostMessage.mock.calls[0][0] as string) as { id: string };
    const call1 = JSON.parse(mockPostMessage.mock.calls[1][0] as string) as { id: string };

    ids.push(call0.id, call1.id);

    expect(ids[0]).toBeTruthy();
    expect(ids[1]).toBeTruthy();
    expect(ids[0]).not.toBe(ids[1]);
  });

  it('ID format includes req- prefix', () => {
    const bridge = makeBridge();
    bridge.call('meta.getOptions').catch(() => {});

    const sent = JSON.parse(mockPostMessage.mock.calls[0][0] as string) as { id: string };
    expect(sent.id).toMatch(/^req-/);
  });

  // ── call() Returns Pending Promise ───────────────────────────────────────

  it('call() returns a pending promise that does not resolve immediately', async () => {
    const bridge = makeBridge();
    let resolved = false;

    bridge.call<{ categories: string[] }>('meta.getOptions').then(() => {
      resolved = true;
    }).catch(() => {});

    // Not resolved synchronously
    expect(resolved).toBe(false);
  });

  it('call() sends correct namespace and method to postMessage', () => {
    const bridge = makeBridge();
    bridge.call('mail.composeNote', { subject: 'Test' }).catch(() => {});

    expect(mockPostMessage).toHaveBeenCalledTimes(1);
    const sent = JSON.parse(mockPostMessage.mock.calls[0][0] as string) as {
      namespace: string;
      method: string;
      params: Record<string, unknown>;
    };

    expect(sent.namespace).toBe('mail');
    expect(sent.method).toBe('composeNote');
    expect(sent.params).toEqual({ subject: 'Test' });
  });

  it('call() sends undefined params when no params provided', () => {
    const bridge = makeBridge();
    bridge.call('meta.getOptions').catch(() => {});

    const sent = JSON.parse(mockPostMessage.mock.calls[0][0] as string) as {
      params?: unknown;
    };
    // params should be absent or undefined when not provided
    expect(sent.params).toBeUndefined();
  });

  // ── receiveResponse() Resolves Correct Promise ───────────────────────────

  it('receiveResponse() with ok:true resolves the matching promise', async () => {
    const bridge = makeBridge();

    const callPromise = bridge.call<{ categories: string[] }>('meta.getOptions');
    const sent = JSON.parse(mockPostMessage.mock.calls[0][0] as string) as { id: string };

    // Simulate native response
    const responseJSON = JSON.stringify({
      id: sent.id,
      ok: true,
      result: { categories: ['Ideas', 'Work'] },
    });

    bridge.receiveResponse(responseJSON);

    const result = await callPromise;
    expect(result.categories).toEqual(['Ideas', 'Work']);
  });

  it('receiveResponse() resolves with null result when result is absent', async () => {
    const bridge = makeBridge();

    const callPromise = bridge.call('camera.capturePhoto');
    const sent = JSON.parse(mockPostMessage.mock.calls[0][0] as string) as { id: string };

    bridge.receiveResponse(JSON.stringify({ id: sent.id, ok: true }));

    const result = await callPromise;
    expect(result).toBeUndefined();
  });

  // ── receiveResponse() with ok:false Rejects Promise ─────────────────────

  it('receiveResponse() with ok:false rejects with BridgeError', async () => {
    const bridge = makeBridge();

    const callPromise = bridge.call('mail.composeNote', {});
    const sent = JSON.parse(mockPostMessage.mock.calls[0][0] as string) as { id: string };

    bridge.receiveResponse(JSON.stringify({
      id: sent.id,
      ok: false,
      error: { code: 'mail_unavailable', message: 'Mail not configured.' },
    }));

    await expect(callPromise).rejects.toThrow('Mail not configured.');
  });

  it('rejected BridgeError has correct code', async () => {
    const bridge = makeBridge();

    const callPromise = bridge.call('mail.composeNote', {});
    const sent = JSON.parse(mockPostMessage.mock.calls[0][0] as string) as { id: string };

    bridge.receiveResponse(JSON.stringify({
      id: sent.id,
      ok: false,
      error: { code: 'mail_unavailable', message: 'Mail not configured.' },
    }));

    let caughtError: unknown;
    try {
      await callPromise;
    } catch (e) {
      caughtError = e;
    }

    expect(caughtError).toBeInstanceOf(BridgeError);
    expect((caughtError as BridgeError).code).toBe('mail_unavailable');
  });

  // ── Unknown Response ID ──────────────────────────────────────────────────

  it('receiveResponse() with unknown ID is silently ignored', () => {
    const bridge = makeBridge();

    // No active calls — receiving a response for an unknown ID should not throw
    expect(() => {
      bridge.receiveResponse(JSON.stringify({
        id: 'req-nonexistent-999',
        ok: true,
        result: {},
      }));
    }).not.toThrow();
  });

  it('receiveResponse() with malformed JSON does not throw', () => {
    const bridge = makeBridge();

    expect(() => {
      bridge.receiveResponse('{ this is not valid json');
    }).not.toThrow();
  });

  // ── Timeout ──────────────────────────────────────────────────────────────

  it('call() rejects with timeout error after specified timeout', async () => {
    const bridge = makeBridge();

    const callPromise = bridge.call('meta.getOptions', undefined, 1000);

    // Advance fake timers past the timeout
    vi.advanceTimersByTime(1001);

    await expect(callPromise).rejects.toThrow(/timeout/i);
  });

  // ── window.nativeBridge Setup ────────────────────────────────────────────

  it('constructor exposes receiveResponse on window.nativeBridge', () => {
    const bridge = makeBridge();
    void bridge; // suppress unused warning

    expect(typeof (window as unknown as { nativeBridge: { receiveResponse: unknown } }).nativeBridge?.receiveResponse).toBe('function');
  });
});
