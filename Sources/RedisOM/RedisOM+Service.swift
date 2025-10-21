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

    /// Implements run to conform to Swift Service Lifecycle
    public func run() async throws {
        await SharedPoolHelper.set(poolService: self.poolService)
        var attempts = 0
        var connected = false

        repeat {
            do {
                try await self.startAndMigrate()
                self.markReady()
                connected = true
                logger.info("RedisOM ready.")
            } catch {
                attempts += 1
                logger.warning(
                    "Redis connection failed: \(error). Retrying in 1s… (attempt \(attempts))")

                switch retryPolicy {
                case .never:
                    throw error
                case .limited(let maxAttempts) where attempts >= maxAttempts:
                    logger.error("Exceeded maximum retry attempts (\(maxAttempts)). Exiting.")
                    throw error
                case .infinite, .limited:
                    try await Task.sleep(for: .seconds(1))
                }
            }
        } while !connected && !Task.isCancelled

        logger.info("Redis connection established, continuing normal operation.")

        // Stay alive until cancelled
        try await cancelWhenGracefulShutdown {
            try await self.waitForCancellation()
        }
    }

    private func waitForCancellation() async throws {
        do {
            // nanoseconds: .max seems bugged in swift 6.1
            try await Task.sleep(for: .seconds(1))
        } catch is CancellationError {
            logger.info("RedisOM shutting down gracefully.")
            do {
                try await self.poolService.close()
            } catch {
                logger.warning("Failed to close Redis pool: \(error)")
            }
        }
    }
}
