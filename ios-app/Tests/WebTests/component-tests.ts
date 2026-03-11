/**
 * component-tests.ts
 * Vitest + JSDOM tests for Web Components
 *
 * Tests run in a jsdom environment (configured in vitest config or via
 * @vitest-environment jsdom directive below).
 *
 * @vitest-environment jsdom
 */
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

// ── Setup ──────────────────────────────────────────────────────────────────

// Polyfill customElements if not present in jsdom version
if (typeof customElements === 'undefined') {
  (globalThis as unknown as Record<string, unknown>).customElements = {
    define: vi.fn(),
    get: vi.fn(),
    whenDefined: vi.fn().mockResolvedValue(undefined),
  };
}

// Helper to create and connect a custom element to the document
function mount<T extends HTMLElement>(tagName: string, html?: string): T {
  const container = document.createElement('div');
  if (html) {
    container.innerHTML = html;
  } else {
    container.innerHTML = `<${tagName}></${tagName}>`;
  }
  document.body.appendChild(container);
  return container.querySelector<T>(tagName)!;
}

function unmount(el: HTMLElement): void {
  el.closest('div')?.remove();
}

// ── StatusBanner Tests ─────────────────────────────────────────────────────

// Manually define StatusBanner for testing (simplified inline version)
class StatusBannerTest extends HTMLElement {
  private timeout: ReturnType<typeof setTimeout> | null = null;

  static get observedAttributes() { return ['type', 'message']; }

  connectedCallback() { this.render(); }

  attributeChangedCallback(_: string, oldVal: string | null, newVal: string | null) {
    if (oldVal === newVal) return;
    if (this.timeout) { clearTimeout(this.timeout); this.timeout = null; }
    this.render();
    if (this.getAttribute('type') === 'success') {
      this.timeout = setTimeout(() => {
        this.setAttribute('type', 'idle');
        this.setAttribute('message', '');
      }, 4000);
    }
  }

  disconnectedCallback() {
    if (this.timeout) clearTimeout(this.timeout);
  }

  private render() {
    const type = this.getAttribute('type') ?? 'idle';
    const message = this.getAttribute('message') ?? '';
    const isVisible = type !== 'idle' && message.length > 0;
    this.classList.toggle('status-banner--visible', isVisible);
    this.textContent = message;
  }
}

if (!customElements.get('status-banner-test')) {
  customElements.define('status-banner-test', StatusBannerTest);
}

// Minimal MetadataForm for testing
class MetadataFormTest extends HTMLElement {
  private options: { categories: string[]; tagOptions: string[] } | null = null;

  connectedCallback() { this.renderShell(); }

  setOptions(opts: { categories: string[]; tagOptions: string[] }) {
    this.options = opts;
    this.populateSelects();
  }

  getValues() {
    return {
      category:     this.getVal('category'),
      tagPrimary:   this.getVal('tagPrimary'),
      tagSecondary: this.getVal('tagSecondary'),
      tagTertiary:  this.getVal('tagTertiary'),
      subject:      this.getInputVal('subject'),
    };
  }

  private renderShell() {
    this.innerHTML = `
      <select name="category"><option value="">None</option></select>
      <select name="tagPrimary"><option value="">None</option></select>
      <select name="tagSecondary"><option value="">None</option></select>
      <select name="tagTertiary"><option value="">None</option></select>
      <input type="text" name="subject" value="" />
    `;
    if (this.options) this.populateSelects();
  }

  private populateSelects() {
    if (!this.options) return;
    ['category'].forEach(name => this.fill(`[name="${name}"]`, this.options!.categories));
    ['tagPrimary', 'tagSecondary', 'tagTertiary'].forEach(name => this.fill(`[name="${name}"]`, this.options!.tagOptions));
  }

  private fill(selector: string, items: string[]) {
    const select = this.querySelector<HTMLSelectElement>(selector);
    if (!select) return;
    select.innerHTML = '<option value="">None</option>';
    items.forEach(item => {
      const opt = document.createElement('option');
      opt.value = item;
      opt.textContent = item;
      select.appendChild(opt);
    });
  }

  private getVal(name: string): string {
    return this.querySelector<HTMLSelectElement>(`[name="${name}"]`)?.value ?? '';
  }

  private getInputVal(name: string): string {
    return this.querySelector<HTMLInputElement>(`[name="${name}"]`)?.value ?? '';
  }
}

if (!customElements.get('metadata-form-test')) {
  customElements.define('metadata-form-test', MetadataFormTest);
}

// ── StatusBanner Component Tests ───────────────────────────────────────────

describe('<status-banner>', () => {
  let el: StatusBannerTest;

  afterEach(() => {
    unmount(el);
  });

  it('is hidden when type is idle', () => {
    el = mount<StatusBannerTest>('status-banner-test', '<status-banner-test type="idle" message="hello"></status-banner-test>');
    expect(el.classList.contains('status-banner--visible')).toBe(false);
  });

  it('is hidden when message is empty even with non-idle type', () => {
    el = mount<StatusBannerTest>('status-banner-test', '<status-banner-test type="success" message=""></status-banner-test>');
    expect(el.classList.contains('status-banner--visible')).toBe(false);
  });

  it('is visible when type is success and message is non-empty', () => {
    el = mount<StatusBannerTest>('status-banner-test', '<status-banner-test type="success" message="Sent!"></status-banner-test>');
    expect(el.classList.contains('status-banner--visible')).toBe(true);
  });

  it('is visible when type is error', () => {
    el = mount<StatusBannerTest>('status-banner-test', '<status-banner-test type="error" message="Oops"></status-banner-test>');
    expect(el.classList.contains('status-banner--visible')).toBe(true);
  });

  it('is visible when type is loading', () => {
    el = mount<StatusBannerTest>('status-banner-test', '<status-banner-test type="loading" message="Sending..."></status-banner-test>');
    expect(el.classList.contains('status-banner--visible')).toBe(true);
  });

  it('displays the message text', () => {
    el = mount<StatusBannerTest>('status-banner-test', '<status-banner-test type="error" message="Something broke"></status-banner-test>');
    expect(el.textContent).toBe('Something broke');
  });

  it('hides after setAttribute to idle', () => {
    el = mount<StatusBannerTest>('status-banner-test', '<status-banner-test type="success" message="Done"></status-banner-test>');
    expect(el.classList.contains('status-banner--visible')).toBe(true);

    el.setAttribute('type', 'idle');
    el.setAttribute('message', '');
    expect(el.classList.contains('status-banner--visible')).toBe(false);
  });

  it('auto-dismisses success after 4 seconds', async () => {
    vi.useFakeTimers();

    el = mount<StatusBannerTest>('status-banner-test');
    el.setAttribute('type', 'success');
    el.setAttribute('message', 'Sent!');

    expect(el.classList.contains('status-banner--visible')).toBe(true);

    vi.advanceTimersByTime(4001);

    expect(el.getAttribute('type')).toBe('idle');
    expect(el.classList.contains('status-banner--visible')).toBe(false);

    vi.useRealTimers();
  });
});

// ── MetadataForm Component Tests ───────────────────────────────────────────

describe('<metadata-form>', () => {
  let el: MetadataFormTest;

  const testOptions = {
    categories: ['Ideas', 'Tasks', 'Work'],
    tagOptions: ['Urgent', 'Important', 'Someday'],
  };

  afterEach(() => {
    unmount(el);
  });

  it('renders all four select fields and subject input', () => {
    el = mount<MetadataFormTest>('metadata-form-test');
    expect(el.querySelector('[name="category"]')).toBeTruthy();
    expect(el.querySelector('[name="tagPrimary"]')).toBeTruthy();
    expect(el.querySelector('[name="tagSecondary"]')).toBeTruthy();
    expect(el.querySelector('[name="tagTertiary"]')).toBeTruthy();
    expect(el.querySelector('[name="subject"]')).toBeTruthy();
  });

  it('setOptions() populates category select with options', () => {
    el = mount<MetadataFormTest>('metadata-form-test');
    el.setOptions(testOptions);

    const select = el.querySelector<HTMLSelectElement>('[name="category"]')!;
    const optionValues = Array.from(select.options).map(o => o.value);

    expect(optionValues).toContain('Ideas');
    expect(optionValues).toContain('Tasks');
    expect(optionValues).toContain('Work');
  });

  it('setOptions() populates all tag selects with tagOptions', () => {
    el = mount<MetadataFormTest>('metadata-form-test');
    el.setOptions(testOptions);

    ['tagPrimary', 'tagSecondary', 'tagTertiary'].forEach(name => {
      const select = el.querySelector<HTMLSelectElement>(`[name="${name}"]`)!;
      const optionValues = Array.from(select.options).map(o => o.value);
      expect(optionValues).toContain('Urgent');
      expect(optionValues).toContain('Important');
    });
  });

  it('getValues() returns correct structure with all empty defaults', () => {
    el = mount<MetadataFormTest>('metadata-form-test');
    const values = el.getValues();

    expect(values).toHaveProperty('category');
    expect(values).toHaveProperty('tagPrimary');
    expect(values).toHaveProperty('tagSecondary');
    expect(values).toHaveProperty('tagTertiary');
    expect(values).toHaveProperty('subject');
  });

  it('getValues() returns empty strings as defaults', () => {
    el = mount<MetadataFormTest>('metadata-form-test');
    const values = el.getValues();

    expect(values.category).toBe('');
    expect(values.tagPrimary).toBe('');
    expect(values.tagSecondary).toBe('');
    expect(values.tagTertiary).toBe('');
    expect(values.subject).toBe('');
  });

  it('getValues() reflects programmatic select value change', () => {
    el = mount<MetadataFormTest>('metadata-form-test');
    el.setOptions(testOptions);

    const categorySelect = el.querySelector<HTMLSelectElement>('[name="category"]')!;
    categorySelect.value = 'Work';

    const values = el.getValues();
    expect(values.category).toBe('Work');
  });

  it('getValues() reflects subject input value', () => {
    el = mount<MetadataFormTest>('metadata-form-test');

    const subjectInput = el.querySelector<HTMLInputElement>('[name="subject"]')!;
    subjectInput.value = 'My Test Subject';

    const values = el.getValues();
    expect(values.subject).toBe('My Test Subject');
  });

  it('setOptions() includes an empty/none option', () => {
    el = mount<MetadataFormTest>('metadata-form-test');
    el.setOptions(testOptions);

    const select = el.querySelector<HTMLSelectElement>('[name="category"]')!;
    const hasEmptyOption = Array.from(select.options).some(o => o.value === '');
    expect(hasEmptyOption).toBe(true);
  });
});
