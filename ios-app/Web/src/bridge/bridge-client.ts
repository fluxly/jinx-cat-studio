import type { BridgeResponse } from '../types/bridge.js';

/** Pending promise handlers stored while waiting for a native response. */
interface PendingCall {
  resolve: (value: unknown) => void;
  reject: (reason: unknown) => void;
  timeoutId: ReturnType<typeof setTimeout>;
}

/** Default timeout for bridge calls in milliseconds. */
const DEFAULT_TIMEOUT_MS = 30_000;

/**
 * BridgeClient manages the JS ↔ Swift message bus.
 *
 * Usage:
 * ```ts
 * import { bridge } from './bridge-client';
 * const result = await bridge.call<MailResult>('mail.composeNote', { body: 'Hello' });
 * ```
 *
 * Internally:
 * - Calls use `window.webkit.messageHandlers.bridge.postMessage` to send to native.
 * - Native sends responses via `window.nativeBridge.receiveResponse(jsonString)`.
 * - Each call has a unique ID used to correlate responses with pending promises.
 */
class BridgeClient {
  private pending = new Map<string, PendingCall>();
  private idCounter = 0;

  constructor() {
    // Expose the receive function on window so native can call it via evaluateJavaScript
    (window as Window & typeof globalThis).nativeBridge = {
      receiveResponse: this.receiveResponse.bind(this),
    };
  }

  /**
   * Calls a native bridge method and returns a Promise that resolves with the result.
   * @param dotMethod - Method in "namespace.method" format, e.g. "mail.composeNote"
   * @param params - Optional parameters object
   * @param timeoutMs - Optional timeout in ms (default 30s)
   * @throws BridgeError if the response has ok=false, or on timeout
   */
  async call<T = unknown>(
    dotMethod: string,
    params?: Record<string, unknown>,
    timeoutMs: number = DEFAULT_TIMEOUT_MS
  ): Promise<T> {
    const [namespace, method] = this.parseDotMethod(dotMethod);
    const id = this.generateId();

    const request = { id, namespace, method, params };
    const requestJSON = JSON.stringify(request);

    return new Promise<T>((resolve, reject) => {
      // Set up timeout
      const timeoutId = setTimeout(() => {
        this.pending.delete(id);
        reject(new BridgeError('timeout', `Bridge call timed out after ${timeoutMs}ms: ${dotMethod}`));
      }, timeoutMs);

      this.pending.set(id, { resolve: resolve as (v: unknown) => void, reject, timeoutId });

      // Send to native
      if (window.webkit?.messageHandlers?.bridge) {
        window.webkit.messageHandlers.bridge.postMessage(requestJSON);
      } else {
        // Running in browser dev mode without native host — resolve with mock for development
        clearTimeout(timeoutId);
        this.pending.delete(id);
        console.warn(`[BridgeClient] No native bridge available for: ${dotMethod}`);
        reject(new BridgeError('no_bridge', 'Native bridge not available (not running in WKWebView)'));
      }
    });
  }

  /**
   * Called by native via `window.nativeBridge.receiveResponse(jsonString)`.
   * Parses the response and resolves or rejects the matching pending promise.
   */
  receiveResponse(jsonString: string): void {
    let response: BridgeResponse<unknown>;

    try {
      response = JSON.parse(jsonString) as BridgeResponse<unknown>;
    } catch (e) {
      console.error('[BridgeClient] Failed to parse response JSON:', jsonString, e);
      return;
    }

    const { id, ok, result, error } = response;

    if (!id) {
      console.error('[BridgeClient] Response missing id:', response);
      return;
    }

    const pending = this.pending.get(id);
    if (!pending) {
      // Unknown ID — may have already timed out
      console.warn('[BridgeClient] Received response for unknown id:', id);
      return;
    }

    clearTimeout(pending.timeoutId);
    this.pending.delete(id);

    if (ok) {
      pending.resolve(result);
    } else {
      const code = error?.code ?? 'unknown_error';
      const message = error?.message ?? 'An unknown error occurred.';
      pending.reject(new BridgeError(code, message));
    }
  }

  // MARK: - Private

  private generateId(): string {
    this.idCounter += 1;
    return `req-${this.idCounter}-${Date.now()}`;
  }

  private parseDotMethod(dotMethod: string): [string, string] {
    const parts = dotMethod.split('.');
    if (parts.length < 2) {
      throw new Error(`Invalid dotMethod format: "${dotMethod}" — expected "namespace.method"`);
    }
    const namespace = parts[0];
    const method = parts.slice(1).join('.');
    return [namespace, method];
  }
}

/**
 * Error thrown when a bridge call fails or times out.
 */
export class BridgeError extends Error {
  constructor(
    public readonly code: string,
    message: string
  ) {
    super(message);
    this.name = 'BridgeError';
  }
}

/** Singleton bridge client instance. Import and use this throughout the app. */
export const bridge = new BridgeClient();

// Also export class for testing
export { BridgeClient };
