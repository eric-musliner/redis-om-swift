extension RedisOM {
    /// Shared startup and migration routine for both Vapor and ServiceLifecycle integrations.
    ///
    /// Ensures the Redis connection pool is initialized and all registered
    /// models have their RedisSearch indexes created via ``Migrator``.
    ///
    /// - Throws: An error if migrations fail or the connection pool cannot be initialized.
    internal func startAndMigrate() async throws {
        let migrator = Migrator(client: poolService, logger: logger)
        try await migrator.migrate(models: registeredModels)
        logger.info("RedisOM migrations completed for \(registeredModels.count) models.")
    }
}
