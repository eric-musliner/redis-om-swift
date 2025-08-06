import ServiceLifecycle

extension RedisOM: Service {

    /// Implements run to adhere to swift service lifecycle service
    @inlinable
    public func run() async throws {
        await SharedPoolHelper.set(pool: self.poolService.connectionPool)

        try? await gracefulShutdown()
        try await self.poolService.close()
    }
}
