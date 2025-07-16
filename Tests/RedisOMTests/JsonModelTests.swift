@preconcurrency import RediStack
import Testing
import NIOCore

@testable import RedisOM

struct User: JsonModel {
    var id: String?
    var name: String
    var email: String

    static let keyPrefix: String = "user"
}

@Test func example() async throws {
    let eventLoop: EventLoop = NIOSingletons.posixEventLoopGroup.any()
    let connection = try await RedisConnection.make(
        configuration: try .init(hostname: "127.0.0.1"),
        boundEventLoop: eventLoop
    ).get()
    
    var user = User(id: "12", name: "Alice2", email: "alice@example.com")
    try await user.save(using: connection)
    print(user.redisKey)
}

@Test func example2() async throws {
    let eventLoop: EventLoop = NIOSingletons.posixEventLoopGroup.any()
    let connection = try await RedisConnection.make(
        configuration: try .init(hostname: "127.0.0.1"),
        boundEventLoop: eventLoop
    ).get()
    
    print(try await User.get(id: "12", using: connection).whenSuccess { user in
        print(user ?? "not found")
    })
}
