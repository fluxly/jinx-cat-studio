import type { MetaOptions } from '../types/meta.js';

/** Values returned from metadata-form.getValues() */
export interface MetadataValues {
  category: string;
  tagPrimary: string;
  tagSecondary: string;
  tagTertiary: string;
  subject: string;
}

/**
 * <metadata-form> Web Component
 *
 * Renders Category, Tag Primary, Tag Secondary, Tag Tertiary dropdowns
 * plus a Subject text input. Options are loaded by calling setOptions().
 *
 * Public API:
 *   setOptions(options: MetaOptions): void
 *   getValues(): MetadataValues
 *
 * Events dispatched:
 *   metadata-change — whenever any field value changes
 */
export class MetadataForm extends HTMLElement {
  private options: MetaOptions | null = null;
  private rendered = false;

  connectedCallback(): void {
    if (!this.rendered) {
      this.renderShell();
      this.rendered = true;
    }
    if (this.options) {
      this.populateSelects();
    }
  }

  /**
   * Sets the option lists for category and tag dropdowns and re-renders selects.
   */
  setOptions(options: MetaOptions): void {
    this.options = options;
    if (this.rendered) {
      this.populateSelects();
    }
  }

  /**
   * Returns the current form values.
   */
  getValues(): MetadataValues {
    return {
      category:     this.getSelectValue('category'),
      tagPrimary:   this.getSelectValue('tagPrimary'),
      tagSecondary: this.getSelectValue('tagSecondary'),
      tagTertiary:  this.getSelectValue('tagTertiary'),
      subject:      this.getInputValue('subject'),
    };
  }

  // MARK: - Private

  private renderShell(): void {
    this.innerHTML = `
      <div class="metadata-form">
        <div class="form-group">
          <label class="form-label" for="mf-category">Category</label>
          <select class="form-select" id="mf-category" name="category">
            <option value="">— None —</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="mf-tagPrimary">Tag Primary</label>
          <select class="form-select" id="mf-tagPrimary" name="tagPrimary">
            <option value="">— None —</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="mf-tagSecondary">Tag Secondary</label>
          <select class="form-select" id="mf-tagSecondary" name="tagSecondary">
            <option value="">— None —</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="mf-tagTertiary">Tag Tertiary</label>
          <select class="form-select" id="mf-tagTertiary" name="tagTertiary">
            <option value="">— None —</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="mf-subject">Subject</label>
          <input
            class="form-input"
            type="text"
            id="mf-subject"
            name="subject"
            placeholder="Optional subject line..."
            autocomplete="off"
            autocorrect="off"
            spellcheck="false"
          />
        </div>
      </div>
    `;

    // Attach change listeners
    this.querySelectorAll('select, input').forEach((el) => {
      el.addEventListener('change', () => this.dispatchChangeEvent());
      el.addEventListener('input', () => this.dispatchChangeEvent());
    });
  }

  private populateSelects(): void {
    if (!this.options) return;

    this.populateSelect('mf-category', this.options.categories);
    this.populateSelect('mf-tagPrimary', this.options.tagOptions);
    this.populateSelect('mf-tagSecondary', this.options.tagOptions);
    this.populateSelect('mf-tagTertiary', this.options.tagOptions);
  }

  private populateSelect(id: string, items: string[]): void {
    const select = this.querySelector<HTMLSelectElement>(`#${id}`);
    if (!select) return;

    // Preserve current selection
    const currentValue = select.value;

    // Clear and re-populate
    select.innerHTML = '<option value="">— None —</option>';
    items.forEach((item) => {
      const option = document.createElement('option');
      option.value = item;
      option.textContent = item;
      select.appendChild(option);
    });

    // Restore selection if still valid
    if (currentValue && items.includes(currentValue)) {
      select.value = currentValue;
    }
  }

  private getSelectValue(name: string): string {
    const el = this.querySelector<HTMLSelectElement>(`[name="${name}"]`);
    return el?.value ?? '';
  }

  private getInputValue(name: string): string {
    const el = this.querySelector<HTMLInputElement>(`[name="${name}"]`);
    return el?.value ?? '';
  }

  private dispatchChangeEvent(): void {
    this.dispatchEvent(new CustomEvent('metadata-change', {
      bubbles: true,
      detail: this.getValues(),
    }));
  }
}

customElements.define('metadata-form', MetadataForm);
