import bridge from '../bridge/bridge-client';
import '../components/document-list';
import '../components/document-editor';
import type { DocumentList } from '../components/document-list';
import type { DocumentEditor } from '../components/document-editor';

export class DocumentsView extends HTMLElement {
  connectedCallback(): void {
    this.style.cssText = 'display:flex;flex:1;overflow:hidden;';
    this.render();
    this.bindEvents();
  }

  private render(): void {
    this.innerHTML = `
      <div class="list-panel">
        <div class="list-panel-header">
          <span class="list-panel-title">Documents</span>
          <button class="btn btn-primary" id="btn-new-doc">+ New</button>
        </div>
        <div class="list-panel-body">
          <document-list id="doc-list"></document-list>
        </div>
      </div>
      <document-editor id="doc-editor" style="display:flex;flex:1;overflow:hidden;"></document-editor>
    `;
  }

  private bindEvents(): void {
    const list = this.querySelector<DocumentList>('#doc-list')!;
    const editor = this.querySelector<DocumentEditor>('#doc-editor')!;
    const newBtn = this.querySelector<HTMLButtonElement>('#btn-new-doc')!;

    list.onSelect = async (id: string) => {
      list.setSelected(id);
      await editor.loadDocument(id);
    };

    editor.onSaved = async () => {
      await list.loadDocuments();
    };

    editor.onDeleted = async () => {
      await list.loadDocuments();
    };

    newBtn.addEventListener('click', async () => {
      try {
        const doc = await bridge.documents.create({});
        await list.loadDocuments();
        list.setSelected(doc.id);
        await editor.loadDocument(doc.id);
      } catch {
        console.error('Failed to create document');
      }
    });
  }
}

customElements.define('document-list-view', DocumentsView);
