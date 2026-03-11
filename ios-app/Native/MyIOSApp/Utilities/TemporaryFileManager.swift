import Foundation

/// Manages the lifecycle of temporary files created during app operation.
///
/// Files written with `writeTemporaryFile` are stored in the system's temporary directory.
/// Call `deleteFile(at:)` or `cleanupAllTemporaryFiles()` to remove them.
struct TemporaryFileManager {

    // MARK: - Write

    /// Writes data to a temporary file with the given filename.
    /// - Parameters:
    ///   - data: The data to write.
    ///   - filename: The filename for the temporary file (e.g., "photo.jpg").
    /// - Returns: The URL of the written file, or nil if the write failed.
    @discardableResult
    static func writeTemporaryFile(data: Data, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
            AppLogger.log(.debug, "TemporaryFileManager: wrote \(data.count) bytes to \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            AppLogger.log(.error, "TemporaryFileManager: failed to write '\(filename)': \(error.localizedDescription)")
            return nil
        }
    }

    /// Writes data to a uniquely-named temporary file to avoid collisions.
    /// The filename is prefixed with a UUID.
    /// - Parameters:
    ///   - data: The data to write.
    ///   - extension: The file extension (e.g., "jpg", "txt").
    /// - Returns: The URL of the written file, or nil if the write failed.
    @discardableResult
    static func writeUniqueTemporaryFile(data: Data, extension fileExtension: String) -> URL? {
        let uniqueName = "\(UUID().uuidString).\(fileExtension)"
        return writeTemporaryFile(data: data, filename: uniqueName)
    }

    // MARK: - Delete

    /// Deletes a file at the given URL if it exists.
    /// - Parameter url: The URL of the file to delete.
    /// - Returns: True if deleted, false if file did not exist or deletion failed.
    @discardableResult
    static func deleteFile(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        do {
            try FileManager.default.removeItem(at: url)
            AppLogger.log(.debug, "TemporaryFileManager: deleted \(url.lastPathComponent)")
            return true
        } catch {
            AppLogger.log(.error, "TemporaryFileManager: failed to delete '\(url.lastPathComponent)': \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Cleanup

    /// Removes all files from the system temporary directory that were written by this app.
    /// This is a best-effort cleanup and ignores individual deletion errors.
    static func cleanupAllTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return
        }

        var deletedCount = 0
        for fileURL in contents {
            if (try? FileManager.default.removeItem(at: fileURL)) != nil {
                deletedCount += 1
            }
        }

        AppLogger.log(.debug, "TemporaryFileManager: cleaned up \(deletedCount) files from temp directory")
    }
}
