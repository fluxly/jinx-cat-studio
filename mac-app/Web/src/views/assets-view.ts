import '../components/asset-list';
import '../components/asset-detail';
import type { AssetList } from '../components/asset-list';
import type { AssetDetail } from '../components/asset-detail';
import type { AssetSummary } from '../types/asset';

export class AssetsView extends HTMLElement {
  private detailPanel: AssetDetail | null = null;

  connectedCallback(): void {
    this.style.cssText = 'display:flex;flex:1;overflow:hidden;position:relative;';
    this.render();
    this.bindEvents();
  }

  private render(): void {
    this.innerHTML = `
      <asset-list id="asset-list"></asset-list>
    `;
  }

  private bindEvents(): void {
    const list = this.querySelector<AssetList>('#asset-list')!;

    list.onSelect = (asset: AssetSummary) => {
      this.showDetail(asset);
    };

    list.onImported = () => {
      // List auto-reloads after import
    };
  }

  private showDetail(asset: AssetSummary): void {
    // Remove existing detail panel
    this.detailPanel?.remove();

    const detail = document.createElement('asset-detail') as AssetDetail;
    document.body.appendChild(detail);
    detail.show(asset);
    this.detailPanel = detail;

    detail.onClose = () => {
      detail.remove();
      this.detailPanel = null;
    };

    detail.onDeleted = async () => {
      detail.remove();
      this.detailPanel = null;
      const list = this.querySelector<AssetList>('#asset-list');
      if (list) await list.loadAssets();
    };
  }
}

customElements.define('asset-list-view', AssetsView);
