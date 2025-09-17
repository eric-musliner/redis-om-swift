import Foundation
import Logging
import NIO
import NIOCore
@preconcurrency import RediStack
import ServiceLifecycle

/// Redis Connection Pool Service to manage creation and configuration of Redis Connection Pool
public struct RedisConnectionPoolService: Sendable {
    private let configuration: RedisConnectionPool.Configuration
    private let logger: Logger
    private let eventLoopGroup: EventLoopGroup
    public let connectionPool: RedisConnectionPool

    /// Create RedisConnectionPoolService
    /// Default pulls url from environment variable `REDIS_URL`
    /// - Returns: RedisConnectionPoolService
    public init() throws {
        let urlStr =
            ProcessInfo.processInfo.environment["REDIS_URL"]
            ?? "redis://localhost:6379"
        guard URL(string: urlStr) != nil else {
            throw RedisError(reason: "Invalid REDIS_URL: \(urlStr)")
        }
        try self.init(url: urlStr)
    }

    /// Create RedisConnectionPoolService
    /// - Parameters:
    ///    - url: Redis connection urlRedis url connection string
    /// - Returns: RedisConnectionPoolService
    public init(url: String) throws {
        guard URL(string: url) != nil else {
            throw RedisError(reason: "Invalid REDIS_URL: \(url)")
        }
        try self.init(
            RedisConfiguration(url: url)
        )
    }

    /// Create RedisConnectionPoolService
    /// - Parameters:
    ///    - config: RedisConfiguration instance
    ///    - eventLoopGroup: optionally pass eventLoopGroup
    ///    - logger: logger for connection pool
    /// - Returns: RedisConnectionPoolService
    public init(
        _ config: RedisConfiguration,
        eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(
            numberOfThreads: System.coreCount
        ),
        logger: Logger = Logger(label: "redis-om-swift.connection-pool")
    ) {
        self.configuration = .init(
            config,
            defaultLogger: logger,
            customClient: nil
        )
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.connectionPool = .init(
            configuration: configuration,
            boundEventLoop: eventLoopGroup.any()
        )
    }

    /// Closes all connections in the pool and deactivates the pool from creating new connections.
    @inlinable
    public func close() async throws {
        let promise = self.eventLoop.makePromise(of: Void.self)
        self.connectionPool.close(promise: promise)
        return try await promise.futureResult.get()
    }
}

extension RedisConnectionPoolService: RedisClient {
    public var eventLoop: NIOCore.EventLoop { self.connectionPool.eventLoop }

    public func send(command: String, with arguments: [RediStack.RESPValue])
        -> EventLoopFuture<RediStack.RESPValue>
    {
        self.connectionPool.send(command: command, with: arguments)
    }

    public func logging(to logger: Logging.Logger) -> RediStack.RedisClient {
        self.connectionPool.logging(to: logger)
    }

    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        self.connectionPool.subscribe(
            to: channels,
            messageReceiver: receiver,
            onSubscribe: subscribeHandler,
            onUnsubscribe: unsubscribeHandler
        )
    }

    public func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        self.connectionPool.psubscribe(
            to: patterns,
            messageReceiver: receiver,
            onSubscribe: subscribeHandler,
            onUnsubscribe: unsubscribeHandler
        )
    }

    public func unsubscribe(from channels: [RediStack.RedisChannelName])
        -> EventLoopFuture<Void>
    {
        self.connectionPool.unsubscribe(from: channels)
    }

    public func punsubscribe(from patterns: [String])
        -> NIOCore.EventLoopFuture<Void>
    {
        self.connectionPool.punsubscribe(from: patterns)
    }

}
