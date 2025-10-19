import ServiceLifecycle

/// Extends ``RedisOM`` to integrate with the Swift Service Lifecycle framework.
///
/// When added to a ``ServiceGroup``, `RedisOM` will:
///  - Initialize and migrate all registered models on startup.
///  - Manage the Redis connection pool lifecycle.
///  - Clean up connections on graceful shutdown.
///
/// Example:
/// ```swift
/// let redis = try RedisOM()
/// redis.register(User.self)
/// let group = ServiceGroup(services: [redis])
/// try await group.run()
/// ```
extension RedisOM: Service {

    /// Implements run to adhere to swift service lifecycle service
    public func run() async throws {
        await SharedPoolHelper.set(poolService: self.poolService)
        try await startAndMigrate()
        try? await gracefulShutdown()
        try await self.poolService.close()
    }
}
