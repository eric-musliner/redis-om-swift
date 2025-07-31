import Testing

@testable import RedisOM

/// Test helper to flush redis after test run
func withFlushedRedis(_ body: @Sendable () async throws -> Void) async throws {
    do {
        Task {
            let client = await SharedPoolHelper.shared()
            _ = client.send(command: "FLUSHALL")
        }
    }
}
