import { bridge, BridgeError } from '../bridge/bridge-client.js';
import { store } from '../state/store.js';
import type { MetaOptions } from '../types/meta.js';
import type { MailResult } from '../types/mail.js';
import type { MetadataForm } from './metadata-form.js';
import './metadata-form.js';
import './status-banner.js';

/**
 * <email-note-view> Web Component
 *
 * Provides the full email note composition UI:
 *   - <metadata-form> for category/tag/subject
 *   - Textarea for note body
 *   - Send button → mail.composeNote bridge call
 *   - Back button → navigate home
 *   - <status-banner> for feedback
 */
export class EmailNoteView extends HTMLElement {
  private _metaOptions: MetaOptions | null = null;

  set metaOptions(options: MetaOptions | null) {
    this._metaOptions = options;
    const form = this.querySelector<MetadataForm>('metadata-form');
    if (form && options) {
      form.setOptions(options);
    }
  }

  connectedCallback(): void {
    this.render();
    if (this._metaOptions) {
      const form = this.querySelector<MetadataForm>('metadata-form');
      if (form) form.setOptions(this._metaOptions);
    }
  }

  private render(): void {
    this.innerHTML = `
      <div class="view">
        <button class="nav-back" type="button" id="env-back">
          ← Back
        </button>

        <div class="card">
          <h2 class="section-title">Email Note</h2>
          <metadata-form></metadata-form>
          <div class="divider"></div>
          <div class="form-group" style="margin-top: 0;">
            <label class="form-label" for="env-body">Note Body</label>
            <textarea
              class="form-textarea"
              id="env-body"
              name="body"
              placeholder="Write your note here..."
              rows="6"
              autocorrect="on"
              spellcheck="true"
            ></textarea>
          </div>
        </div>

        <status-banner id="env-status" type="idle" message=""></status-banner>

        <div class="actions">
          <button class="btn btn--primary btn--full" type="button" id="env-send">
            Send Note
          </button>
        </div>
      </div>
    `;

    this.querySelector('#env-back')?.addEventListener('click', () => this.navigateHome());
    this.querySelector('#env-send')?.addEventListener('click', () => this.handleSend());
  }

  private navigateHome(): void {
    this.dispatchEvent(new CustomEvent('navigate', {
      bubbles: true,
      detail: { view: 'home' },
    }));
  }

  private async handleSend(): Promise<void> {
    const form = this.querySelector<MetadataForm>('metadata-form');
    if (!form) return;

    const values = form.getValues();
    const body = (this.querySelector<HTMLTextAreaElement>('#env-body')?.value ?? '').trim();
    const sendBtn = this.querySelector<HTMLButtonElement>('#env-send');
    const banner = this.querySelector<HTMLElement>('#env-status');

    this.setStatus('loading', 'Opening mail composer...');
    if (sendBtn) sendBtn.disabled = true;

    const params: Record<string, unknown> = {
      category:     values.category     || undefined,
      tagPrimary:   values.tagPrimary   || undefined,
      tagSecondary: values.tagSecondary || undefined,
      tagTertiary:  values.tagTertiary  || undefined,
      subject:      values.subject      || undefined,
      body:         body                || undefined,
    };

    try {
      const result = await bridge.call<MailResult>('mail.composeNote', params);
      const statusMap: Record<string, string> = {
        sent:      'Note sent successfully.',
        saved:     'Note saved as draft.',
        cancelled: 'Compose cancelled.',
        failed:    'Send failed. Please try again.',
      };
      const message = statusMap[result.status] ?? `Status: ${result.status}`;
      const type = result.status === 'sent' ? 'success'
        : result.status === 'cancelled' ? 'idle'
        : result.status === 'failed' ? 'error'
        : 'success';

      this.setStatus(type as 'success' | 'error' | 'idle' | 'loading', message);
      store.setState({ status: { type: type as 'success' | 'error' | 'idle' | 'loading', message } });

    } catch (err) {
      const message = err instanceof BridgeError
        ? err.message
        : 'An unexpected error occurred.';
      this.setStatus('error', message);
      banner; // reference to avoid unused warning
    } finally {
      if (sendBtn) sendBtn.disabled = false;
    }
  }

  private setStatus(type: 'idle' | 'success' | 'error' | 'loading', message: string): void {
    const banner = this.querySelector<HTMLElement>('#env-status');
    if (banner) {
      banner.setAttribute('type', type);
      banner.setAttribute('message', message);
    }
  }
}

customElements.define('email-note-view', EmailNoteView);
