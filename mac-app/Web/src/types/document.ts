export interface DocumentSummary {
  id: string;
  title: string;
  body_snippet: string;
  createdAt: string;
  updatedAt: string;
  tags: import('./tag').Tag[];
  categories: import('./category').Category[];
}

export interface Document extends DocumentSummary {
  body: string;
  assets: import('./asset').AssetSummary[];
}

export interface CreateDocumentPayload {
  title?: string;
  body?: string;
}

export interface UpdateDocumentPayload {
  title?: string;
  body?: string;
}
