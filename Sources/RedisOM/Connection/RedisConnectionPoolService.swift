//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2023 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Logging
import NIO
import NIOCore
@preconcurrency import RediStack
import ServiceLifecycle

// Based on Hummingbird Redis ConnectionPoolService.
// https://github.com/hummingbird-project/hummingbird-redis/blob/main/Sources/HummingbirdRedis/RedisConfiguration.swift
// Modifications made to initialization and member attributes

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

extension RedisConnectionPoolService {
    /// A unique identifer to represent this connection.
    @inlinable
    public var id: UUID { self.connectionPool.id }
    /// The count of connections that are active and available for use.
    @inlinable
    public var availableConnectionCount: Int { self.connectionPool.availableConnectionCount }
    /// The number of connections that have been handed out and are in active use.
    @inlinable
    public var leasedConnectionCount: Int { self.connectionPool.leasedConnectionCount }
    /// Provides limited exclusive access to a connection to be used in a user-defined specialized closure of operations.
    /// - Warning: Attempting to create PubSub subscriptions with connections leased in the closure will result in a failed `NIO.EventLoopFuture`.
    ///
    /// `RedisConnectionPool` manages PubSub state and requires exclusive control over creating PubSub subscriptions.
    /// - Important: This connection **MUST NOT** be stored outside of the closure. It is only available exclusively within the closure.
    ///
    /// All operations should be done inside the closure as chained `NIO.EventLoopFuture` callbacks.
    ///
    /// For example:
    /// ```swift
    /// let countFuture = pool.leaseConnection {
    ///     let client = $0.logging(to: myLogger)
    ///     return client.authorize(with: userPassword)
    ///         .flatMap { connection.select(database: userDatabase) }
    ///         .flatMap { connection.increment(counterKey) }
    /// }
    /// ```
    /// - Warning: Some commands change the state of the connection that are not tracked client-side,
    /// and will not be automatically reset when the connection is returned to the pool.
    ///
    /// When the connection is reused from the pool, it will retain this state and may affect future commands executed with it.
    ///
    /// For example, if `select(database:)` is used, all future commands made with this connection will be against the selected database.
    ///
    /// To protect against future issues, make sure the final commands executed are to reset the connection to it's previous known state.
    /// - Parameter operation: A closure that receives exclusive access to the provided `RedisConnection` for the lifetime of the closure for specialized Redis command chains.
    /// - Returns: A `NIO.EventLoopFuture` that resolves the value of the `NIO.EventLoopFuture` in the provided closure operation.
    @inlinable
    public func leaseConnection<T>(_ operation: @escaping (RedisConnection) -> EventLoopFuture<T>)
        -> EventLoopFuture<T>
    {
        self.connectionPool.leaseConnection(operation)
    }

    /// Updates the list of valid connection addresses.
    /// - Warning: This will replace any previously set list of addresses.
    /// - Note: This does not invalidate existing connections: as long as those connections continue to stay up, they will be kept by
    /// this client.
    ///
    /// However, no new connections will be made to any endpoint that is not in `newAddresses`.
    /// - Parameters:
    ///     - newAddresses: The new addresses to connect to in future connections.
    ///     - logger: An optional logger to use for any log statements generated while updating the target addresses.
    ///         If one is not provided, the pool will use its default logger.
    @inlinable
    public func updateConnectionAddresses(_ newAddresses: [SocketAddress], logger: Logger? = nil) {
        self.connectionPool.updateConnectionAddresses(newAddresses)
    }
}

extension RedisConnectionPoolService: RedisClient {
    public var eventLoop: NIOCore.EventLoop { self.connectionPool.eventLoop }

    public func send(command: String, with arguments: [RediStack.RESPValue])
        -> EventLoopFuture<RediStack.RESPValue>
    {
        self.connectionPool.leaseConnection { connection in
            connection.send(command: command, with: arguments)
        }
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
