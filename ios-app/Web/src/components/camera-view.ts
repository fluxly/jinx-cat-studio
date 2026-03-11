import { bridge, BridgeError } from '../bridge/bridge-client.js';
import { store } from '../state/store.js';
import type { MetaOptions } from '../types/meta.js';
import type { CaptureResult } from '../types/camera.js';
import type { MailResult } from '../types/mail.js';
import type { MetadataForm } from './metadata-form.js';
import './metadata-form.js';
import './status-banner.js';

/**
 * <camera-view> Web Component
 *
 * Camera capture and photo email composition view:
 *   - "Capture Photo" → camera.capturePhoto bridge call
 *   - Shows captured image preview
 *   - <metadata-form> for email metadata
 *   - "Send Photo" → mail.composePhoto bridge call
 *   - Back navigation
 *   - <status-banner> for feedback
 */
export class CameraView extends HTMLElement {
  private _metaOptions: MetaOptions | null = null;
  private _capturedBase64: string | null = null;

  set metaOptions(options: MetaOptions | null) {
    this._metaOptions = options;
    const form = this.querySelector<MetadataForm>('metadata-form');
    if (form && options) {
      form.setOptions(options);
    }
  }

  set capturedImage(base64: string | null) {
    this._capturedBase64 = base64;
    this.updateImagePreview();
    this.updateSendButton();
  }

  connectedCallback(): void {
    this.render();

    // Restore image from store if navigating back to this view
    const storeImage = store.getState().capturedImageBase64;
    if (storeImage) {
      this._capturedBase64 = storeImage;
      this.updateImagePreview();
      this.updateSendButton();
    }

    if (this._metaOptions) {
      const form = this.querySelector<MetadataForm>('metadata-form');
      if (form) form.setOptions(this._metaOptions);
    }
  }

  private render(): void {
    this.innerHTML = `
      <div class="view">
        <button class="nav-back" type="button" id="cv-back">
          ← Back
        </button>

        <div class="card">
          <h2 class="section-title">Camera</h2>

          <div id="cv-preview-container">
            <div class="photo-preview photo-preview--placeholder" id="cv-placeholder">
              No photo captured yet
            </div>
            <img
              class="photo-preview"
              id="cv-preview"
              alt="Captured photo preview"
              style="display:none;"
            />
          </div>

          <div class="actions" style="margin-top: 16px;">
            <button class="btn btn--secondary btn--full" type="button" id="cv-capture">
              Capture Photo
            </button>
          </div>
        </div>

        <div class="card" id="cv-meta-card">
          <h2 class="section-title">Email Metadata</h2>
          <metadata-form></metadata-form>
        </div>

        <status-banner id="cv-status" type="idle" message=""></status-banner>

        <div class="actions">
          <button class="btn btn--primary btn--full" type="button" id="cv-send" disabled>
            Send Photo
          </button>
        </div>
      </div>
    `;

    this.querySelector('#cv-back')?.addEventListener('click', () => this.navigateHome());
    this.querySelector('#cv-capture')?.addEventListener('click', () => this.handleCapture());
    this.querySelector('#cv-send')?.addEventListener('click', () => this.handleSend());

    if (this._metaOptions) {
      const form = this.querySelector<MetadataForm>('metadata-form');
      if (form) form.setOptions(this._metaOptions);
    }
  }

  private navigateHome(): void {
    this.dispatchEvent(new CustomEvent('navigate', {
      bubbles: true,
      detail: { view: 'home' },
    }));
  }

  private async handleCapture(): Promise<void> {
    const captureBtn = this.querySelector<HTMLButtonElement>('#cv-capture');
    if (captureBtn) captureBtn.disabled = true;

    this.setStatus('loading', 'Opening camera...');

    try {
      const result = await bridge.call<CaptureResult>('camera.capturePhoto');

      if (result.status === 'captured' && result.imageBase64) {
        this._capturedBase64 = result.imageBase64;
        store.setState({ capturedImageBase64: result.imageBase64 });
        this.updateImagePreview();
        this.updateSendButton();
        this.setStatus('idle', '');
      } else if (result.status === 'cancelled') {
        this.setStatus('idle', '');
      } else if (result.status === 'unavailable') {
        this.setStatus('error', 'Camera is not available on this device.');
      } else {
        const message = result.error ?? 'Photo capture failed.';
        this.setStatus('error', message);
      }

    } catch (err) {
      const message = err instanceof BridgeError ? err.message : 'An unexpected error occurred.';
      this.setStatus('error', message);
    } finally {
      if (captureBtn) captureBtn.disabled = false;
    }
  }

  private async handleSend(): Promise<void> {
    if (!this._capturedBase64) {
      this.setStatus('error', 'No photo to send. Capture a photo first.');
      return;
    }

    const form = this.querySelector<MetadataForm>('metadata-form');
    if (!form) return;

    const values = form.getValues();
    const sendBtn = this.querySelector<HTMLButtonElement>('#cv-send');

    this.setStatus('loading', 'Opening mail composer...');
    if (sendBtn) sendBtn.disabled = true;

    const params: Record<string, unknown> = {
      category:     values.category     || undefined,
      tagPrimary:   values.tagPrimary   || undefined,
      tagSecondary: values.tagSecondary || undefined,
      tagTertiary:  values.tagTertiary  || undefined,
      subject:      values.subject      || undefined,
      imageBase64:  this._capturedBase64,
    };

    try {
      const result = await bridge.call<MailResult>('mail.composePhoto', params);
      const statusMap: Record<string, string> = {
        sent:      'Photo sent successfully.',
        saved:     'Email saved as draft.',
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
      const message = err instanceof BridgeError ? err.message : 'An unexpected error occurred.';
      this.setStatus('error', message);
    } finally {
      if (sendBtn) sendBtn.disabled = false;
    }
  }

  private updateImagePreview(): void {
    const placeholder = this.querySelector<HTMLElement>('#cv-placeholder');
    const preview = this.querySelector<HTMLImageElement>('#cv-preview');

    if (!placeholder || !preview) return;

    if (this._capturedBase64) {
      preview.src = `data:image/jpeg;base64,${this._capturedBase64}`;
      preview.style.display = 'block';
      placeholder.style.display = 'none';
    } else {
      preview.style.display = 'none';
      placeholder.style.display = 'flex';
    }
  }

  private updateSendButton(): void {
    const sendBtn = this.querySelector<HTMLButtonElement>('#cv-send');
    if (sendBtn) {
      sendBtn.disabled = !this._capturedBase64;
    }
  }

  private setStatus(type: 'idle' | 'success' | 'error' | 'loading', message: string): void {
    const banner = this.querySelector<HTMLElement>('#cv-status');
    if (banner) {
      banner.setAttribute('type', type);
      banner.setAttribute('message', message);
    }
  }
}

customElements.define('camera-view', CameraView);
