import Foundation
import NIOCore
@preconcurrency import RediStack
import Testing

@testable import RedisOM

struct User: JsonModel {
    var id: String?
    var name: String
    var email: String
    var age: Int?
    var createdAt: Date?

    static let keyPrefix: String = "user"
}

@Test func testSave() async throws {
    let eventLoop: EventLoop = NIOSingletons.posixEventLoopGroup.any()
    let connection = try await RedisConnection.make(
        configuration: try .init(hostname: "127.0.0.1"),
        boundEventLoop: eventLoop
    ).get()

    var user = User(
        id: "12",
        name: "Alice2",
        email: "alice@example.com",
        age: 33,
        createdAt: Date()
    )
    try await user.save(using: connection)

    // Check the key exists
    let exists = try await connection.exists(user.getRedisKey()).get()
    #expect(exists == 1)

    // Fetch JSON from Redis
    let response = try await connection.send(
        command: "JSON.GET",
        with: [.bulkString(ByteBuffer(string: user.redisKey))]
    ).get()

    let jsonString = try #require(response.string)
    let data = try #require(jsonString.data(using: .utf8))

    let decoded = try JSONDecoder().decode(User.self, from: data)
    #expect(decoded.id == "12")
    #expect(decoded.name == "Alice2")
    #expect(decoded.email == "alice@example.com")
    #expect(decoded.age == 33)
    #expect(decoded.createdAt == user.createdAt)
}

@Test func testGet() async throws {
    let eventLoop: EventLoop = NIOSingletons.posixEventLoopGroup.any()
    let connection = try await RedisConnection.make(
        configuration: try .init(hostname: "127.0.0.1"),
        boundEventLoop: eventLoop
    ).get()

    print(
        try await User.get(id: "12", using: connection).whenSuccess { user in
            print(user ?? "not found")
        }
    )
}
