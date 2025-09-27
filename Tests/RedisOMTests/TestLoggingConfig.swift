import Foundation
import Logging

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel =
            ProcessInfo.processInfo.environment["LOG_LEVEL"].flatMap { .init(rawValue: $0) }
            ?? .critical
        return handler
    }
    return true
}()
