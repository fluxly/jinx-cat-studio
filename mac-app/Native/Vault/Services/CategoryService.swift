import Foundation

final class CategoryService {
    private let repo: CategoryRepository

    init(repo: CategoryRepository) {
        self.repo = repo
    }

    func listCategories() throws -> [CategoryDTO] {
        try repo.findAll().map { CategoryDTO(from: $0) }
    }

    func getCategory(_ id: String) throws -> CategoryDTO {
        guard let cat = try repo.findById(id) else {
            throw BridgeError.notFound("Category '\(id)' not found")
        }
        return CategoryDTO(from: cat)
    }

    func createCategory(name: String, parentId: String?) throws -> CategoryDTO {
        // Validate parent exists
        if let parentId = parentId {
            guard try repo.exists(parentId) else {
                throw BridgeError.notFound("Parent category '\(parentId)' not found")
            }
        }
        // Check for duplicate name
        if let existing = try repo.findByName(name) {
            return CategoryDTO(from: existing)
        }
        let category = Category(id: UUID().uuidString, name: name, parentId: parentId)
        try repo.insert(category)
        return CategoryDTO(from: category)
    }

    func updateCategory(_ id: String, name: String?, parentId: String??) throws -> CategoryDTO {
        guard var category = try repo.findById(id) else {
            throw BridgeError.notFound("Category '\(id)' not found")
        }
        if let name = name { category.name = name }
        if let parentId = parentId {
            // parentId is String?? — outer optional means "was provided", inner means "null value"
            if let pid = parentId {
                guard try repo.exists(pid) else {
                    throw BridgeError.notFound("Parent category '\(pid)' not found")
                }
            }
            category.parentId = parentId
        }
        try repo.update(category)
        return CategoryDTO(from: category)
    }

    func deleteCategory(_ id: String) throws {
        guard try repo.exists(id) else {
            throw BridgeError.notFound("Category '\(id)' not found")
        }
        try repo.delete(id)
    }
}
