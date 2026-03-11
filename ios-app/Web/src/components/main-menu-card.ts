import type { AppView } from '../state/store.js';

/**
 * <main-menu-card> Web Component
 *
 * Renders two large card buttons: "Email / Note" and "Camera".
 * Dispatches a `navigate` event with `detail: { view: AppView }` when a card is tapped.
 */
export class MainMenuCard extends HTMLElement {
  connectedCallback(): void {
    this.render();
  }

  private render(): void {
    this.innerHTML = `
      <div class="home-view__cards">
        <div class="card card--interactive menu-card" data-view="email" role="button" tabindex="0" aria-label="Email / Note">
          <div class="menu-card__icon">✉️</div>
          <h2 class="menu-card__title">Email / Note</h2>
          <p class="menu-card__subtitle">Compose and send a structured note</p>
        </div>
        <div class="card card--interactive menu-card" data-view="camera" role="button" tabindex="0" aria-label="Camera">
          <div class="menu-card__icon">📷</div>
          <h2 class="menu-card__title">Camera</h2>
          <p class="menu-card__subtitle">Capture a photo and send it by email</p>
        </div>
      </div>
    `;

    this.querySelectorAll<HTMLElement>('[data-view]').forEach((card) => {
      card.addEventListener('click', () => this.handleCardTap(card));
      card.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          this.handleCardTap(card);
        }
      });
    });
  }

  private handleCardTap(card: HTMLElement): void {
    const view = card.dataset['view'] as AppView | undefined;
    if (!view) return;

    this.dispatchEvent(new CustomEvent('navigate', {
      bubbles: true,
      detail: { view },
    }));
  }
}

customElements.define('main-menu-card', MainMenuCard);
