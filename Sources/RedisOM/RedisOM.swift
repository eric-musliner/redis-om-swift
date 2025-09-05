import Foundation
import Logging
import NIO
@preconcurrency import RediStack
import ServiceLifecycle

/// Redis OM client for use with Service Lifecycle applications
/// Creates and manages RedisConnectionPoolService
public final class RedisOM: @unchecked Sendable {

    internal let logger: Logger
    private let config: RedisConfiguration
    public var poolService: RedisConnectionPoolService
    internal var registeredModels: [any RedisModel.Type] = []

    /// Default constructor to create RedisOM from environment variable configuration
    /// Pulls configuration from environment variable`REDIS_URL`
    public convenience init() throws {
        let urlStr =
            ProcessInfo.processInfo.environment["REDIS_URL"]
            ?? "redis://localhost:6379"
        guard URL(string: urlStr) != nil else {
            throw RedisError(reason: "Invalid REDIS_URL: \(urlStr)")
        }
        try self.init(url: urlStr)
    }

    /// Create RedisOM
    /// - Parameters:
    ///    - url: Redis connection url
    /// - Returns: RedisOM
    public init(
        url: String,
        logger: Logger = .init(label: "redis-om-swift.client")
    ) throws {
        guard let redisURL = URL(string: url) else {
            throw RedisError(reason: "Invalid Redis URL: \(url)")
        }
        self.config = try RedisConfiguration(url: redisURL)
        self.logger = logger
        self.poolService = RedisConnectionPoolService(config)
    }

    /// Create RedisOM with supplied RedisConfiguration
    /// - Parameters:
    ///    - config: RedisConfiguration
    /// - Returns: RedisOM
    public init(
        config: RedisConfiguration,
        logger: Logger = .init(label: "redis-om-swift.client")
    ) throws {
        self.config = config
        self.logger = logger
        self.poolService = RedisConnectionPoolService(config)
    }

    /// Register model to be handled by Migrator to create index for indexed fields
    /// - Parameters:
    ///    - model: RedisModel type
    public func register(_ model: any RedisModel.Type) {
        registeredModels.append(model)
    }

}
