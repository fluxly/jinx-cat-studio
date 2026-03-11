/**
 * Re-exports and helper types for the bridge layer.
 */

export type { BridgeRequest, BridgeResponse, BridgeErrorPayload } from '../types/bridge.js';

/** The webkit message handler interface exposed by WKWebView */
export interface WebKitMessageHandlers {
  bridge: {
    postMessage: (message: string) => void;
  };
}

/** The nativeBridge interface set up by BridgeClient on window */
export interface NativeBridgeInterface {
  receiveResponse: (jsonString: string) => void;
}

/** Extends Window with WKWebView-injected globals */
declare global {
  interface Window {
    webkit?: {
      messageHandlers: WebKitMessageHandlers;
    };
    nativeBridge?: NativeBridgeInterface;
  }
}
