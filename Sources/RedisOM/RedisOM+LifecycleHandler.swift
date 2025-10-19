import Vapor

/// Extends ``RedisOM`` to integrate with the Vapor application lifecycle.
///
/// When attached to a `Vapor.Application`, this handler:
///  - Initializes the shared Redis connection pool.
///  - Runs the ``Migrator`` to create RedisSearch indexes for all registered models.
///  - Gracefully closes connections on shutdown.
///
/// Add this in your Vapor app’s configuration:
/// ```swift
/// let redis = try RedisOM()
/// redis.register(User.self)
/// app.lifecycle.use(redis)
/// ```
extension RedisOM: LifecycleHandler {

    public func willBoot(_ app: Application) throws {
        Task {
            await SharedPoolHelper.set(poolService: self.poolService)

            var attempts = 0
            var connected = false

            repeat {
                do {
                    try await self.startAndMigrate()
                    connected = true
                    self.markReady()
                    logger.info("RedisOM ready.")
                } catch {
                    attempts += 1
                    logger.warning("Redis connection failed during willBoot: \(error). Retrying…")
                    switch retryPolicy {
                    case .never:
                        connected = true
                    case .limited(let max) where attempts >= max:
                        connected = true
                    default:
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
            } while !connected && !Task.isCancelled
        }
    }

    public func didBoot(_ app: Application) throws {
        // Nothing to do — pool remains open and available for the lifetime of the app.
        logger.debug("RedisOM didBoot: pool remains active.")
    }

    public func shutdownAsync(_ app: Application) async {
        do {
            try await poolService.close()
            logger.info("RedisOM pool closed on shutdown.")
        } catch {
            logger.warning("RedisOM pool close failed: \(error)")
        }
    }
}
