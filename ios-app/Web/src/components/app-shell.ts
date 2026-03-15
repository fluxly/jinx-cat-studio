import { bridge } from '../bridge/bridge-client.js';
import { store } from '../state/store.js';
import type { AppView } from '../state/store.js';
import type { MetaOptions } from '../types/meta.js';
import './main-menu-card.js';
import './email-note-view.js';
import './camera-view.js';

/**
 * <app-shell> Web Component
 *
 * Top-level routing shell. Manages view transitions based on store.currentView.
 * Loads meta options on startup via meta.getOptions bridge call.
 * Listens for `navigate` events from child components.
 */
export class AppShell extends HTMLElement {
  private unsubscribe: (() => void) | null = null;

  connectedCallback(): void {
    this.render();
    this.listenForNavigation();

    // Subscribe to store changes to re-render on view change
    this.unsubscribe = store.subscribe(() => this.render());

    // Load meta options on startup
    this.loadMetaOptions();
  }

  disconnectedCallback(): void {
    this.unsubscribe?.();
    this.unsubscribe = null;
  }

  private render(): void {
    const state = store.getState();
    const view = state.currentView;

    // Determine if we need to do a full re-render or just show/hide views
    this.innerHTML = `

      <div class="app-container">
        ${view === 'home'   ? this.renderHome()   : ''}
        ${view === 'email'  ? this.renderEmail()  : ''}
        ${view === 'camera' ? this.renderCamera() : ''}
      </div>
    `;

    // Inject meta options into views that need them
    const metaOptions = state.metaOptions;
    if (metaOptions) {
      this.injectMetaOptions(metaOptions);
    }

    // Restore captured image into camera view
    const capturedBase64 = state.capturedImageBase64;
    if (capturedBase64 && view === 'camera') {
      const cameraView = this.querySelector('camera-view') as (HTMLElement & { capturedImage: string | null }) | null;
      if (cameraView) {
        cameraView.capturedImage = capturedBase64;
      }
    }
  }

  private renderHome(): string {
    return `
      <div class="home-view view">
        <div class="home-view__header">
          <h1 class="home-view__title">Utility App</h1>
          <p class="home-view__subtitle">Choose an action below</p>
        </div>
        <main-menu-card></main-menu-card>
      </div>
    `;
  }

  private renderEmail(): string {
    return '<email-note-view></email-note-view>';
  }

  private renderCamera(): string {
    return '<camera-view></camera-view>';
  }

  private injectMetaOptions(metaOptions: MetaOptions): void {
    const emailView = this.querySelector('email-note-view') as (HTMLElement & { metaOptions: MetaOptions | null }) | null;
    if (emailView) emailView.metaOptions = metaOptions;

    const cameraView = this.querySelector('camera-view') as (HTMLElement & { metaOptions: MetaOptions | null }) | null;
    if (cameraView) cameraView.metaOptions = metaOptions;
  }

  private listenForNavigation(): void {
    this.addEventListener('navigate', (e: Event) => {
      const customEvent = e as CustomEvent<{ view: AppView }>;
      const { view } = customEvent.detail;
      store.setState({ currentView: view, status: null });
    });
  }

  private async loadMetaOptions(): Promise<void> {
    try {
      const options = await bridge.call<MetaOptions>('meta.getOptions');
      store.setState({ metaOptions: options });
    } catch (err) {
      console.warn('[AppShell] Failed to load meta options:', err);
      // Fall back to hardcoded defaults so UI is never broken
      store.setState({
        metaOptions: {
          categories: ['Ideas', 'Tasks', 'Reference', 'Journal', 'Project', 'Personal', 'Work', 'Other'],
          tagOptions: ['Urgent', 'Important', 'Someday', 'Waiting', 'Active', 'Backlog', 'Done', 'Other'],
        },
      });
    }
  }
}

customElements.define('app-shell', AppShell);
