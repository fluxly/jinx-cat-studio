import type { Tag } from './tag';
import type { Category } from './category';

export interface AssetSummary {
  id: string;
  filename: string;
  original_filename: string;
  mimeType: string;
  fileSize: number;
  sha256: string;
  createdAt: string;
  updatedAt: string;
  tags: Tag[];
  categories: Category[];
}
