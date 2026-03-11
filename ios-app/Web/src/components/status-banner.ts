/**
 * <status-banner> Web Component
 *
 * Attributes:
 *   type    — "success" | "error" | "loading" | "idle"
 *   message — The text to display
 *
 * Behavior:
 *   - Visible when type is "success", "error", or "loading"
 *   - Hidden when type is "idle" or absent
 *   - Auto-dismisses success banners after 4 seconds
 */
export class StatusBanner extends HTMLElement {
  private autoHideTimeout: ReturnType<typeof setTimeout> | null = null;

  static get observedAttributes(): string[] {
    return ['type', 'message'];
  }

  connectedCallback(): void {
    this.render();
  }

  attributeChangedCallback(_name: string, oldValue: string | null, newValue: string | null): void {
    if (oldValue === newValue) return;

    // Clear any pending auto-hide on attribute change
    if (this.autoHideTimeout !== null) {
      clearTimeout(this.autoHideTimeout);
      this.autoHideTimeout = null;
    }

    this.render();

    // Schedule auto-dismiss for success type
    if (this.getAttribute('type') === 'success') {
      this.autoHideTimeout = setTimeout(() => {
        this.setAttribute('type', 'idle');
        this.setAttribute('message', '');
      }, 4000);
    }
  }

  disconnectedCallback(): void {
    if (this.autoHideTimeout !== null) {
      clearTimeout(this.autoHideTimeout);
      this.autoHideTimeout = null;
    }
  }

  private render(): void {
    const type = this.getAttribute('type') ?? 'idle';
    const message = this.getAttribute('message') ?? '';
    const isVisible = type !== 'idle' && message.length > 0;

    const classNames = ['status-banner'];
    if (isVisible) classNames.push('status-banner--visible');
    if (type === 'success') classNames.push('status-banner--success');
    else if (type === 'error') classNames.push('status-banner--error');
    else if (type === 'loading') classNames.push('status-banner--loading');

    this.className = classNames.join(' ');
    this.setAttribute('role', isVisible ? 'alert' : 'none');
    this.setAttribute('aria-live', 'polite');
    this.textContent = message;
  }
}

customElements.define('status-banner', StatusBanner);
