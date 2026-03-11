import Foundation

struct SearchResult {
    let type: String   // "document" or "asset"
    let id: String
    let title: String
    let snippet: String
    let score: Double
}

struct SearchResultDTO: Encodable {
    let type: String
    let id: String
    let title: String
    let snippet: String
    let score: Double
}

final class SearchService {
    private let db: SQLiteManager

    init(db: SQLiteManager) {
        self.db = db
    }

    func search(query: String, limit: Int = 50) throws -> [SearchResultDTO] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // Escape special FTS5 characters
        let safeQuery = escapeFTS5Query(query)

        var results: [SearchResultDTO] = []

        // Search documents
        let docRows = try db.query("""
            SELECT d.id, d.title, d.body,
                   rank AS score
            FROM documents_fts
            JOIN documents d ON d.id = documents_fts.id
            WHERE documents_fts MATCH ?
            ORDER BY rank
            LIMIT ?;
        """, parameters: [safeQuery, limit])

        for row in docRows {
            guard let id = row["id"] as? String,
                  let title = row["title"] as? String,
                  let body = row["body"] as? String else { continue }
            let score = (row["score"] as? Double) ?? 0
            let snippet = makeSnippet(from: body, query: query)
            results.append(SearchResultDTO(type: "document", id: id, title: title, snippet: snippet, score: score))
        }

        // Search assets
        let assetRows = try db.query("""
            SELECT a.id, a.original_filename AS title, a.filename,
                   rank AS score
            FROM assets_fts
            JOIN assets a ON a.id = assets_fts.id
            WHERE assets_fts MATCH ?
            ORDER BY rank
            LIMIT ?;
        """, parameters: [safeQuery, limit])

        for row in assetRows {
            guard let id = row["id"] as? String,
                  let title = row["title"] as? String else { continue }
            let score = (row["score"] as? Double) ?? 0
            results.append(SearchResultDTO(type: "asset", id: id, title: title, snippet: "", score: score))
        }

        // Sort combined results by score (FTS5 rank is negative; lower = better)
        results.sort { $0.score < $1.score }
        return Array(results.prefix(limit))
    }

    private func escapeFTS5Query(_ query: String) -> String {
        // Wrap each token in double-quotes for phrase matching, or just append * for prefix search
        let tokens = query.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"*" }
        return tokens.joined(separator: " ")
    }

    private func makeSnippet(from text: String, query: String, maxLength: Int = 200) -> String {
        let lowercased = text.lowercased()
        let lowQuery = query.lowercased()

        if let range = lowercased.range(of: lowQuery) {
            let start = max(text.startIndex, text.index(range.lowerBound, offsetBy: -50, limitedBy: text.startIndex) ?? text.startIndex)
            let end = min(text.endIndex, text.index(range.upperBound, offsetBy: 100, limitedBy: text.endIndex) ?? text.endIndex)
            var snippet = String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            if start > text.startIndex { snippet = "..." + snippet }
            if end < text.endIndex { snippet = snippet + "..." }
            return snippet
        }

        return String(text.prefix(maxLength))
    }
}
