import Foundation
import Logging
import NIO
@preconcurrency import RediStack
import ServiceLifecycle

/// A top-level Redis OM client that manages connections, configuration,
/// and model registration for Redis-OM–based applications.
///
/// `RedisOM` acts as the primary entry point for integrating RedisSearch,
/// RedisJSON, and model indexing capabilities in your application.
/// It encapsulates a `RedisConnectionPoolService` for efficient,
/// lifecycle-managed Redis connection pooling.
///
/// This client is fully compatible with the Swift `ServiceLifecycle` framework,
/// making it suitable for use in long-running server applications.
///
/// ## Features
/// - Automatic configuration via `REDIS_URL` environment variable
/// - Connection pooling through ``RedisConnectionPoolService``
/// - Model registration for schema migration and index creation
/// - Logging integration via SwiftLog
///
public final class RedisOM: @unchecked Sendable {

    internal let logger: Logger
    private let config: RedisConfiguration
    public var poolService: RedisConnectionPoolService
    internal var registeredModels: [any RedisModel.Type] = []

    // MARK: Initializers

    /// Creates a `RedisOM` client using environment variable configuration.
    ///
    /// This initializer reads the Redis connection URL from the `REDIS_URL`
    /// environment variable. If not found, it defaults to `redis://localhost:6379`.
    ///
    /// Example:
    /// ```bash
    /// export REDIS_URL=redis://localhost:6380
    /// ```
    /// ```swift
    /// let redis = try RedisOM()
    /// ```
    ///
    /// - Throws: ``RedisError`` if the URL is invalid or cannot be parsed.
    public convenience init() throws {
        let urlStr =
            ProcessInfo.processInfo.environment["REDIS_URL"]
            ?? "redis://localhost:6379"
        guard URL(string: urlStr) != nil else {
            throw RedisError(reason: "Invalid REDIS_URL: \(urlStr)")
        }
        try self.init(url: urlStr)
    }

    /// Creates a `RedisOM` client with a Redis connection URL.
    ///
    /// - Parameters:
    ///   - url: The Redis connection URL (e.g. `"redis://localhost:6379"`).
    ///   - logger: An optional `Logger` instance for logging Redis activity.
    /// - Throws: ``RedisError`` if the URL cannot be parsed.
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

    /// Creates a `RedisOM` client with an explicit Redis configuration.
    ///
    /// Use this initializer when you need to construct a configuration programmatically.
    ///
    /// - Parameters:
    ///   - config: A ``RedisConfiguration`` instance describing host, port, and authentication.
    ///   - logger: An optional `Logger` instance for Redis client logs.
    public init(
        config: RedisConfiguration,
        logger: Logger = .init(label: "redis-om-swift.client")
    ) throws {
        self.config = config
        self.logger = logger
        self.poolService = RedisConnectionPoolService(config)
    }

    // MARK: Model Registration

    /// Registers a model type for use with Redis OM migrations.
    ///
    /// Registered models are discovered by the ``Migrator`` during startup
    /// to automatically generate RedisSearch indexes for all indexed fields.
    ///
    /// Example:
    /// ```swift
    /// let redis = try RedisOM()
    /// redis.register(User.self)
    ///
    /// try await Migrator(redis: redis).migrate()
    /// ```
    ///
    /// - Parameter model: The model type to register, conforming to ``RedisModel``.
    public func register(_ model: any RedisModel.Type) {
        registeredModels.append(model)
    }

}
