import type { MetaOptions } from '../types/meta.js';

/** Available top-level views in the app. */
export type AppView = 'home' | 'email' | 'camera';

/** Status banner state. */
export interface StatusState {
  type: 'idle' | 'success' | 'error' | 'loading';
  message: string;
}

/** The full application state. */
export interface AppState {
  currentView: AppView;
  metaOptions: MetaOptions | null;
  capturedImageBase64: string | null;
  status: StatusState | null;
}

/** A listener function called whenever state changes. */
type Listener = () => void;

/**
 * Simple synchronous reactive store.
 *
 * Usage:
 * ```ts
 * import { store } from './store';
 *
 * // Subscribe to changes
 * const unsubscribe = store.subscribe(() => {
 *   const state = store.getState();
 *   render(state);
 * });
 *
 * // Update state
 * store.setState({ currentView: 'email' });
 *
 * // Unsubscribe
 * unsubscribe();
 * ```
 */
class Store {
  private state: AppState = {
    currentView: 'home',
    metaOptions: null,
    capturedImageBase64: null,
    status: null,
  };

  private listeners: Set<Listener> = new Set();

  /**
   * Subscribe to state changes.
   * @returns An unsubscribe function.
   */
  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  /** Returns a reference to the current state object. */
  getState(): Readonly<AppState> {
    return this.state;
  }

  /**
   * Merges the provided partial state into the current state and notifies listeners.
   * @param partial - Partial state update.
   */
  setState(partial: Partial<AppState>): void {
    this.state = { ...this.state, ...partial };
    this.notify();
  }

  private notify(): void {
    this.listeners.forEach((listener) => {
      try {
        listener();
      } catch (e) {
        console.error('[Store] Listener threw an error:', e);
      }
    });
  }
}

/** Singleton store instance. Import and use throughout the app. */
export const store = new Store();
