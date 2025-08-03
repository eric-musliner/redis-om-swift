import Testing

@testable import RedisOM

/// Test helper to flush redis after test run
func withFlushedRedis(_ body: () async throws -> Void) async throws {
    defer {
        Task {
            let client = await SharedPoolHelper.shared()
            _ = try await client.send(command: "FLUSHALL").get()
        }
    }
    try await body()
}
