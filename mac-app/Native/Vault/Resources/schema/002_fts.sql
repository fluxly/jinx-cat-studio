CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
    id UNINDEXED,
    title,
    body,
    content=documents,
    content_rowid=rowid
);

CREATE VIRTUAL TABLE IF NOT EXISTS assets_fts USING fts5(
    id UNINDEXED,
    filename,
    original_filename,
    content=assets,
    content_rowid=rowid
);

CREATE TRIGGER IF NOT EXISTS documents_ai AFTER INSERT ON documents BEGIN
    INSERT INTO documents_fts(rowid, id, title, body) VALUES (new.rowid, new.id, new.title, new.body);
END;
CREATE TRIGGER IF NOT EXISTS documents_ad AFTER DELETE ON documents BEGIN
    INSERT INTO documents_fts(documents_fts, rowid, id, title, body) VALUES ('delete', old.rowid, old.id, old.title, old.body);
END;
CREATE TRIGGER IF NOT EXISTS documents_au AFTER UPDATE ON documents BEGIN
    INSERT INTO documents_fts(documents_fts, rowid, id, title, body) VALUES ('delete', old.rowid, old.id, old.title, old.body);
    INSERT INTO documents_fts(rowid, id, title, body) VALUES (new.rowid, new.id, new.title, new.body);
END;

CREATE TRIGGER IF NOT EXISTS assets_ai AFTER INSERT ON assets BEGIN
    INSERT INTO assets_fts(rowid, id, filename, original_filename) VALUES (new.rowid, new.id, new.filename, new.original_filename);
END;
CREATE TRIGGER IF NOT EXISTS assets_ad AFTER DELETE ON assets BEGIN
    INSERT INTO assets_fts(assets_fts, rowid, id, filename, original_filename) VALUES ('delete', old.rowid, old.id, old.filename, old.original_filename);
END;
CREATE TRIGGER IF NOT EXISTS assets_au AFTER UPDATE ON assets BEGIN
    INSERT INTO assets_fts(assets_fts, rowid, id, filename, original_filename) VALUES ('delete', old.rowid, old.id, old.filename, old.original_filename);
    INSERT INTO assets_fts(rowid, id, filename, original_filename) VALUES (new.rowid, new.id, new.filename, new.original_filename);
END;
