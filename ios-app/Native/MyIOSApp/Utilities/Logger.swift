import Foundation

// MARK: - LogLevel

/// Severity levels for structured app logging.
enum LogLevel: Int, CustomStringConvertible {
    case debug   = 0
    case info    = 1
    case warning = 2
    case error   = 3

    var description: String {
        switch self {
        case .debug:   return "DEBUG"
        case .info:    return "INFO"
        case .warning: return "WARN"
        case .error:   return "ERROR"
        }
    }

    /// Emoji prefix for console readability (optional, used in debug builds only).
    var prefix: String {
        switch self {
        case .debug:   return "🔍"
        case .info:    return "ℹ️"
        case .warning: return "⚠️"
        case .error:   return "🔴"
        }
    }
}

// MARK: - AppLogger

/// Simple structured logger that writes to the console in debug builds.
/// In release builds, only warnings and errors are printed.
struct AppLogger {

    // MARK: - Configuration

    /// The minimum log level to output. Override in tests or configure at startup.
    #if DEBUG
    static var minimumLevel: LogLevel = .debug
    #else
    static var minimumLevel: LogLevel = .warning
    #endif

    // MARK: - Logging

    /// Logs a message at the specified level.
    /// - Parameters:
    ///   - level: The severity level.
    ///   - message: The message to log.
    ///   - file: Source file (auto-captured by compiler).
    ///   - function: Function name (auto-captured by compiler).
    ///   - line: Line number (auto-captured by compiler).
    static func log(
        _ level: LogLevel,
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let filename = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logTimestamp.string(from: Date())

        #if DEBUG
        let output = "\(level.prefix) [\(timestamp)] [\(level)] \(filename):\(line) \(function) — \(message)"
        #else
        let output = "[\(timestamp)] [\(level)] \(filename):\(line) — \(message)"
        #endif

        print(output)
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()
}
