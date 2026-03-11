import Foundation

final class TagService {
    private let repo: TagRepository

    init(repo: TagRepository) {
        self.repo = repo
    }

    func listTags() throws -> [TagDTO] {
        try repo.findAll().map { TagDTO(from: $0) }
    }

    func createTag(name: String, color: String) throws -> TagDTO {
        // Check for duplicate name
        if let existing = try repo.findByName(name) {
            return TagDTO(from: existing)
        }
        let tag = Tag(id: UUID().uuidString, name: name, color: color)
        try repo.insert(tag)
        return TagDTO(from: tag)
    }

    func updateTag(_ id: String, name: String?, color: String?) throws -> TagDTO {
        guard var tag = try repo.findById(id) else {
            throw BridgeError.notFound("Tag '\(id)' not found")
        }
        if let name = name { tag.name = name }
        if let color = color { tag.color = color }
        try repo.update(tag)
        return TagDTO(from: tag)
    }

    func deleteTag(_ id: String) throws {
        guard try repo.exists(id) else {
            throw BridgeError.notFound("Tag '\(id)' not found")
        }
        try repo.delete(id)
    }

    func getTag(_ id: String) throws -> TagDTO {
        guard let tag = try repo.findById(id) else {
            throw BridgeError.notFound("Tag '\(id)' not found")
        }
        return TagDTO(from: tag)
    }
}
