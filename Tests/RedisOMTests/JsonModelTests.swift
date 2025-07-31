import Foundation
import NIOCore
@preconcurrency import RediStack
import Testing

@testable import RedisOM

// MARK: Test models
struct User: JsonModel {
    var id: String?
    var name: String
    var email: String
    var aliases: [String]?
    var age: Int?
    var notes: [Note]?
    var createdAt: Date?

    static let keyPrefix: String = "user"
}

struct Note: JsonModel {
    var id: String?
    var description: String
    var createdAt: Date?

    static let keyPrefix: String = "note"
}

// MARK: JsonModelTest Suite
@Suite("JsonModelTests")
struct JsonModelTests {

    let connectionPool: RedisConnectionPool
    let redisOM: RedisOM

    init() async throws {
        let url = "redis://localhost:6379"
        self.redisOM = try RedisOM(url: url)
        await SharedPoolHelper.set(pool: self.redisOM.poolService.connectionPool)
        self.connectionPool = await SharedPoolHelper.shared()
    }


    @Test func testSaveWithAutomaticIdAssign() async throws {
        var user = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        // Check the key exists
        let exists = try await self.connectionPool.exists(user.getRedisKey())
            .get()
        #expect(exists == 1)

        // Fetch JSON from Redis
        let response = try await self.connectionPool.send(
            command: "JSON.GET",
            with: [.bulkString(ByteBuffer(string: user.redisKey))]
        ).get()

        let jsonString = try #require(response.string)
        let data = try #require(jsonString.data(using: .utf8))

        let decoded = try JSONDecoder().decode(User.self, from: data)
        #expect(decoded.id == user.id)
        #expect(decoded.name == "Alice")
        #expect(decoded.email == "alice@example.com")
        #expect(decoded.aliases == ["Alicia", "alice"])
        #expect(decoded.age == 33)
        #expect(decoded.createdAt == user.createdAt)
        
    }

    @Test func testSaveWithIdSupplied() async throws {
        var user = User(
            id: "12",
            name: "Alice",
            email: "alice@example.com",
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        // Check the key exists
        let exists = try await self.connectionPool.exists(user.getRedisKey())
            .get()
        #expect(exists == 1)

        // Fetch JSON from Redis
        let response = try await self.connectionPool.send(
            command: "JSON.GET",
            with: [.bulkString(ByteBuffer(string: user.redisKey))]
        ).get()

        let jsonString = try #require(response.string)
        let data = try #require(jsonString.data(using: .utf8))

        let decoded = try JSONDecoder().decode(User.self, from: data)
        #expect(decoded.id == user.id)
        #expect(decoded.name == "Alice")
        #expect(decoded.email == "alice@example.com")
        #expect(decoded.age == 33)
        #expect(decoded.createdAt == user.createdAt)
    }

    @Test func testSaveWithNestedModels() async throws {
        var user = User(
            name: "Alice",
            email: "alice@example.com",
            age: 33,
            notes: [.init(description: "Applied to ACME")],
            createdAt: Date(),
        )
        try await user.save()

        // Check the key exists
        let exists = try await self.connectionPool.exists(user.getRedisKey())
            .get()
        #expect(exists == 1)

        // Fetch JSON from Redis
        let response = try await self.connectionPool.send(
            command: "JSON.GET",
            with: [.bulkString(ByteBuffer(string: user.redisKey))]
        ).get()

        let jsonString = try #require(response.string)
        let data = try #require(jsonString.data(using: .utf8))

        let decoded = try JSONDecoder().decode(User.self, from: data)
        #expect(decoded.id == user.id)
        #expect(decoded.name == "Alice")
        #expect(decoded.email == "alice@example.com")
        #expect(decoded.age == 33)
        #expect(decoded.notes?.count == 1)
        #expect(decoded.notes?[0].description == "Applied to ACME")
        #expect(decoded.createdAt == user.createdAt)
    }

    @Test func testGetById() async throws {
        var user = User(
            id: "123",
            name: "Alice",
            email: "alice@example.com",
            age: 33,
            notes: [.init(description: "Applied to ACME")],
            createdAt: Date(),
        )
        try await user.save()

        // Get from redis
        let actual: User = try #require(try await User.get(id: "123"))

        #expect(actual.id == user.id)
        #expect(actual.name == "Alice")
        #expect(actual.email == "alice@example.com")
        #expect(actual.age == 33)
        #expect(actual.notes!.count == 1)
        #expect(actual.createdAt == user.createdAt)
    }

    @Test func testGetNotFound() async throws {
        let actual: User? = try await User.get(id: "123")
        #expect(actual == nil)
    }

    @Test func testDelete() async throws {
        var user = User(
            name: "Alice",
            email: "alice@example.com",
            age: 33,
            notes: [.init(description: "Applied to ACME")],
            createdAt: Date(),
        )
        try await user.save()

        // Get from redis
        _ = try #require(try await User.get(id: user.id!))

        try await user.delete()

        let actual: User? = try await User.get(id: "123")
        #expect(actual == nil)
    }
    
    @Test func testDeleteById() async throws {
        var user = User(
            name: "Alice",
            email: "alice@example.com",
            age: 33,
            notes: [.init(description: "Applied to ACME")],
            createdAt: Date(),
        )
        try await user.save()

        // Get from redis
        _ = try #require(try await User.get(id: user.id!))

        try await User.delete(id: user.id!)

        let actual: User? = try await User.get(id: "123")
        #expect(actual == nil)
    }
    
}
