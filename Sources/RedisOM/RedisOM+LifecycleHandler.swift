import Vapor

/// Extends `RedisOM` to participate in the application lifecycle.
///
/// During `willBoot`, this hook automatically runs the `Migrator` to ensure that
/// all Redis search indexes required by registered models are created before the
/// application starts handling requests.
extension RedisOM: LifecycleHandler {

    public func willBoot(_ application: Application) throws {
        // Kick of migrations to create indexes
        Task {
            do {
                let connection = poolService.connectionPool
                let migrator = Migrator(client: connection, logger: logger)
                try await migrator.migrate(models: registeredModels)
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
        } catch {
            self.logger.warning("Failed to close Redis connection pool: \(error)")
        }
    }
}
