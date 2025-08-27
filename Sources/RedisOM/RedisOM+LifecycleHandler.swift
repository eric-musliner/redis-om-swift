import Vapor

extension RedisOM: LifecycleHandler {

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
