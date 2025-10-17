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

    public func willBoot(_ application: Application) throws {
        // Kick of migrations to create indexes
        Task {
            do {
                try await startAndMigrate()
            } catch {
                logger.error("Migration failed during willBoot: \(error)")
            }
        }
    }

    public func didBoot(_ app: Application) throws {
        // Start the service using the service-lifecycle run
        Task {
            try await run()
        }
    }

    public func shutdownAsync(_ app: Application) async {
        do {
            try await poolService.close()
            logger.info("RedisOM pool closed successfully.")
        } catch {
            self.logger.warning("Failed to close Redis connection pool: \(error)")
        }
    }
}
