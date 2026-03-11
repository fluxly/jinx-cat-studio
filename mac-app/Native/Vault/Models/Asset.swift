import Foundation

struct Asset {
    let id: String
    var filename: String
    var originalFilename: String
    var mimeType: String
    var fileSize: Int64
    var sha256: String
    let createdAt: String
    var updatedAt: String

    init(id: String = UUID().uuidString,
         filename: String,
         originalFilename: String,
         mimeType: String,
         fileSize: Int64 = 0,
         sha256: String = "",
         createdAt: String = ISO8601DateFormatter().string(from: Date()),
         updatedAt: String = ISO8601DateFormatter().string(from: Date())) {
        self.id = id
        self.filename = filename
        self.originalFilename = originalFilename
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.sha256 = sha256
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
