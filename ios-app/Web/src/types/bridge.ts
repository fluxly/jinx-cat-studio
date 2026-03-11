/**
 * Core type definitions for the JS ↔ Swift bridge protocol.
 */

/** An outbound request from JS to native. */
export interface BridgeRequest {
  id: string;
  namespace: string;
  method: string;
  params?: Record<string, unknown>;
}

/** An inbound response from native to JS. */
export interface BridgeResponse<T = unknown> {
  id: string;
  ok: boolean;
  result?: T;
  error?: BridgeErrorPayload;
}

/** The error payload inside a failed BridgeResponse. */
export interface BridgeErrorPayload {
  code: string;
  message: string;
}
