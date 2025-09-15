import Foundation
import NIOCore
@preconcurrency import RediStack
import Testing

@testable import RedisOM

// MARK: Migrator Test Suite
@Suite("MigratorTests")
final class MigratorTests {

    let connectionPool: RedisConnectionPool
    let redisOM: RedisOM
    let migrator: Migrator

    init() async throws {
        self.redisOM = try RedisOM()
        await SharedPoolHelper.set(
            pool: self.redisOM.poolService.connectionPool
        )
        self.connectionPool = await SharedPoolHelper.shared()
        self.migrator = Migrator(client: self.connectionPool, logger: .init(label: "MigratorTests"))
    }

    deinit {
        Task {
            let client = await SharedPoolHelper.shared()
            _ = try await client.send(command: "FLUSHALL").get()

        }
    }

    @Test func testMigratePersonIndexes() async throws {
        try await self.migrator.migrate(models: [Person.self])

        // Assert index exists (FT.INFO idx:Person)
        let listResponse = try await self.connectionPool.send(command: "FT._LIST").get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Person"))

        // Get index details
        let fields: [(String, String)] = try await inspectIndex(name: "idx:Person")

        // Assert expected indexes for schema
        let expected: [(String, String)] = [
            ("id", "TAG"),
            ("name", "TAG"),
            ("email", "TAG"),
        ]
        for (field, fieldType) in expected {
            #expect(fields.contains(where: { $0.0 == field && $0.1 == fieldType }))
        }
    }

    @Test func testMigrateArrayNestedModelIndexes() async throws {
        try await self.migrator.migrate(models: [User.self])

        let listResponse = try await self.connectionPool.send(command: "FT._LIST").get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:User"))

        // Get index details
        let fields: [(String, String)] = try await inspectIndex(name: "idx:User")

        // Assert expected indexes for schema
        let expected: [(String, String)] = [
            ("id", "TAG"),
            ("name", "TEXT"),
            ("email", "TAG"),
            ("notes.id", "TAG"),
            ("address.id", "TAG"),
            ("address.city", "TAG"),
            ("address.postalCode", "TAG"),
            ("address.note.id", "TAG"),
            ("address.note.description", "TEXT"),
        ]
        for (field, fieldType) in expected {
            #expect(fields.contains(where: { $0.0 == field && $0.1 == fieldType }))
        }
    }

    @Test func testMigrateArrayNestedModelMissingSchemaAttrIndexes() async throws {
        try await self.migrator.migrate(models: [Node.self])

        // Assert index exists
        let listResponse = try await self.connectionPool.send(command: "FT._LIST").get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Node"))

        // Get index details
        let fields: [(String, String)] = try await inspectIndex(name: "idx:Node")

        // Assert expected indexes for schema
        let expected: [(String, String)] = [
            ("id", "TAG")

        ]
        for (field, fieldType) in expected {
            #expect(fields.contains(where: { $0.0 == field && $0.1 == fieldType }))
        }
    }

    @Test func testMigrateDictNestedModelIndexes() async throws {
        try await self.migrator.migrate(models: [Author.self])

        // Assert index exists
        let listResponse = try await self.connectionPool.send(command: "FT._LIST").get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Author"))

        // Get index details
        let fields: [(String, String)] = try await inspectIndex(name: "idx:Author")

        // Assert expected indexes for schema
        let expected: [(String, String)] = [
            ("id", "TAG"),
            ("name", "TAG"),
            ("email", "TAG"),
            ("notes.id", "TAG"),
            ("notes.description", "TEXT"),
        ]
        for (field, fieldType) in expected {
            #expect(fields.contains(where: { $0.0 == field && $0.1 == fieldType }))
        }
    }

    @Test func testMigrateBikeIndexes() async throws {
        try await self.migrator.migrate(models: [Bike.self])

        // Assert index exists (FT.INFO idx:Bike)
        let listResponse = try await self.connectionPool.send(command: "FT._LIST").get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Bike"))

        // Get index details
        let fields: [(String, String)] = try await inspectIndex(name: "idx:Bike")

        // Assert expected indexes for schema
        let expected: [(String, String)] = [
            ("id", "TAG"),
            ("model", "TAG"),
            ("brand", "TAG"),
            ("price", "NUMERIC"),
            ("type", "TAG"),
            ("description", "TEXT"),
            ("helmetIncluded", "TAG"),
            ("specs.material", "TAG"),
            ("specs.weight", "NUMERIC"),
        ]
        for (field, fieldType) in expected {
            #expect(fields.contains(where: { $0.0 == field && $0.1 == fieldType }))
        }
    }

    @Test func testMigrateOrderIndexes() async throws {
        try await self.migrator.migrate(models: [Order.self])

        // Assert index exists
        let listResponse = try await self.connectionPool.send(command: "FT._LIST").get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Order"))

        // Get index details
        let fields: [(String, String)] = try await inspectIndex(name: "idx:Order")

        // Assert expected indexes for schema
        let expected: [(String, String)] = [
            ("id", "TAG"),
            ("items.id", "TAG"),
            ("items.name", "TAG"),
        ]
        for (field, fieldType) in expected {
            #expect(fields.contains(where: { $0.0 == field && $0.1 == fieldType }))
        }
    }

    /// Helper to inspect Index by name
    func inspectIndex(name: String) async throws -> [(String, String)] {
        let infoResponse = try await self.connectionPool.send(
            command: "FT.INFO", with: [.bulkString(ByteBuffer(string: name))]
        ).get()

        let infoArray = try #require(infoResponse.array)

        //  ["index_name", "idx:Person", "attributes", [ [...], [...], ... ]]
        var attributes: [RESPValue]?
        var i = 0
        while i < infoArray.count {
            if infoArray[i].string == "attributes" {
                attributes = infoArray[i + 1].array
            }
            i += 2
        }

        let attrs = try #require(attributes)

        // Each entry is [ "identifier", "$.name", "attribute", "name", "type", "TEXT", ... ]
        let fields = attrs.compactMap({ $0.array }).compactMap({ entry -> (String, String)? in
            var id: String?
            var type: String?
            var j = 0
            while j < entry.count {
                if entry[j].string == "attribute" {
                    id = entry[j + 1].string
                } else if entry[j].string == "type" {
                    type = entry[j + 1].string
                }
                j += 2
            }
            if let id = id, let type = type {
                return (id, type)
            }
            return nil
        })
        return fields
    }
}
