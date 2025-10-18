import Foundation
import NIOCore
@preconcurrency import RediStack
import Testing

@testable import RedisOM

// MARK: Migrator Test Suite
@Suite("MigratorTests")
final class MigratorTests {

    let poolService: RedisConnectionPoolService
    let redisOM: RedisOM
    let migrator: Migrator

    init() async throws {
        // Silence log output during tests
        #expect(isLoggingConfigured)

        self.redisOM = try RedisOM()
        await SharedPoolHelper.set(
            poolService: self.redisOM.poolService
        )
        self.poolService = await SharedPoolHelper.shared()
        self.migrator = Migrator(client: self.poolService, logger: .init(label: "MigratorTests"))
    }

    deinit {
        Task {
            let poolService = await SharedPoolHelper.shared()
            _ = try await poolService.leaseConnection { connection in
                connection.send(command: "FLUSHALL")
            }.get()
        }
    }

    @Test func testMigrateNoModelsProvided() async throws {
        try await self.migrator.migrate(models: [])

        let listResponse = try await self.poolService.leaseConnection { connection in
            connection.send(command: "FT._LIST")
        }.get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.isEmpty)
    }

    @Test func testMigrateModelNoSchemaAttribute() async throws {
        struct InvalidModel: JsonModel {
            @Id var id: String?
            var name: String
            static let keyPrefix: String = "invalid"
        }

        try await self.migrator.migrate(models: [InvalidModel.self])

        let listResponse = try await self.poolService.leaseConnection { connection in
            connection.send(command: "FT._LIST")
        }.get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.isEmpty)
    }

    @Test func testMigrateNestedModelIndexes() async throws {
        try await self.migrator.migrate(models: [Person.self])

        // Assert index exists (FT.INFO idx:Person)
        let listResponse = try await self.poolService.leaseConnection { connection in
            connection.send(command: "FT._LIST")
        }.get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Person"))

        // Get index details
        let fields: [(String, String, String)] = try await inspectIndex(name: "idx:Person")

        // Assert expected indexes for schema
        let expected: [(String, String, String)] = [
            ("$.id", "id", "TAG"),
            ("$.name", "name", "TAG"),
            ("$.email", "email", "TAG"),
            ("$.createdAt", "createdAt", "NUMERIC"),
            ("$.address.id", "address__id", "TAG"),
            ("$.address.city", "address__city", "TAG"),
            ("$.address.postalCode", "address__postalCode", "TAG"),
            ("$.address.note.id", "address__note__id", "TAG"),
            ("$.address.note.description", "address__note__description", "TEXT"),
        ]
        for (field, fieldAttr, fieldType) in expected {
            #expect(
                fields.contains(where: { $0.0 == field && $0.1 == fieldAttr && $0.2 == fieldType }))
        }
    }

    @Test func testMigrateArrayNestedArrayCollectionIndexes() async throws {
        try await self.migrator.migrate(models: [User.self])

        let listResponse = try await self.poolService.leaseConnection { connection in
            connection.send(command: "FT._LIST")
        }.get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:User"))

        // Get index details
        let fields: [(String, String, String)] = try await inspectIndex(name: "idx:User")

        // Assert expected indexes for schema
        let expected: [(String, String, String)] = [
            ("$.id", "id", "TAG"),
            ("$.name", "name", "TEXT"),
            ("$.email", "email", "TAG"),
            ("$.aliases[*]", "aliases", "TAG"),
            ("$.age", "age", "NUMERIC"),
            ("$.createdAt", "createdAt", "NUMERIC"),
            ("$.notes[*].id", "notes__id", "TAG"),
            ("$.notes[*].description", "notes__description", "TEXT"),
            ("$.address[*].id", "address__id", "TAG"),
            ("$.address[*].city", "address__city", "TAG"),
            ("$.address[*].postalCode", "address__postalCode", "TAG"),
            ("$.address[*].note.id", "address__note__id", "TAG"),
            ("$.address[*].note.description", "address__note__description", "TEXT"),
        ]
        for (field, fieldAttr, fieldType) in expected {
            #expect(
                fields.contains(where: { $0.0 == field && $0.1 == fieldAttr && $0.2 == fieldType }))
        }
    }

    @Test func testMigrateArrayNestedModelMissingSchemaAttrIndexes() async throws {
        try await self.migrator.migrate(models: [Node.self])

        // Assert index exists
        let listResponse = try await self.poolService.leaseConnection { connection in
            connection.send(command: "FT._LIST")
        }.get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Node"))

        // Get index details
        let fields: [(String, String, String)] = try await inspectIndex(name: "idx:Node")

        // Assert expected indexes for schema
        let expected: [(String, String, String)] = [
            ("$.id", "id", "TAG")

        ]
        for (field, fieldAttr, fieldType) in expected {
            #expect(
                fields.contains(where: { $0.0 == field && $0.1 == fieldAttr && $0.2 == fieldType }))
        }
    }

    @Test func testMigrateBikeIndexes() async throws {
        try await self.migrator.migrate(models: [Bike.self])

        // Assert index exists (FT.INFO idx:Bike)
        let listResponse = try await self.poolService.leaseConnection { connection in
            connection.send(command: "FT._LIST")
        }.get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Bike"))

        // Get index details
        let fields: [(String, String, String)] = try await inspectIndex(name: "idx:Bike")

        // Assert expected indexes for schema
        let expected: [(String, String, String)] = [
            ("$.id", "id", "TAG"),
            ("$.model", "model", "TAG"),
            ("$.brand", "brand", "TAG"),
            ("$.price", "price", "NUMERIC"),
            ("$.type", "type", "TAG"),
            ("$.description", "description", "TEXT"),
            ("$.helmetIncluded", "helmetIncluded", "TAG"),
            ("$.specs.material", "specs__material", "TAG"),
            ("$.specs.weight", "specs__weight", "NUMERIC"),
        ]
        for (field, fieldAttr, fieldType) in expected {
            #expect(
                fields.contains(where: { $0.0 == field && $0.1 == fieldAttr && $0.2 == fieldType }))
        }
    }

    @Test func testMigrateOrderIndexes() async throws {
        try await self.migrator.migrate(models: [Order.self])

        // Assert index exists
        let listResponse = try await self.poolService.leaseConnection { connection in
            connection.send(command: "FT._LIST")
        }.get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Order"))

        // Get index details
        let fields: [(String, String, String)] = try await inspectIndex(name: "idx:Order")

        // Assert expected indexes for schema
        let expected: [(String, String, String)] = [
            ("$.id", "id", "TAG"),
            ("$.items[*].id", "items__id", "TAG"),
            ("$.items[*].price", "items__price", "NUMERIC"),
            ("$.items[*].name", "items__name", "TAG"),
        ]
        for (field, fieldAttr, fieldType) in expected {
            #expect(
                fields.contains(where: { $0.0 == field && $0.1 == fieldAttr && $0.2 == fieldType }))
        }
    }

    @Test func testMigrateMultipleModels() async throws {
        try await self.migrator.migrate(models: [Person.self, User.self])

        // Assert index exists
        let listResponse = try await self.poolService.leaseConnection { connection in
            connection.send(command: "FT._LIST")
        }.get()
        let indexNames = listResponse.array?.compactMap({ $0.string })
        #expect(indexNames!.contains("idx:Person"))
        #expect(indexNames!.contains("idx:User"))

        // Assert Person Index
        var fields: [(String, String, String)] = try await inspectIndex(name: "idx:Person")

        // Assert expected indexes for Person schema
        var expected: [(String, String, String)] = [
            ("$.id", "id", "TAG"),
            ("$.name", "name", "TAG"),
            ("$.email", "email", "TAG"),
            ("$.createdAt", "createdAt", "NUMERIC"),
        ]
        for (field, fieldAttr, fieldType) in expected {
            #expect(
                fields.contains(where: { $0.0 == field && $0.1 == fieldAttr && $0.2 == fieldType }))
        }
        // Assert User Index
        fields = try await inspectIndex(name: "idx:User")

        // Assert expected indexes for User schema
        expected = [
            ("$.id", "id", "TAG"),
            ("$.name", "name", "TEXT"),
            ("$.email", "email", "TAG"),
            ("$.aliases[*]", "aliases", "TAG"),
            ("$.age", "age", "NUMERIC"),
            ("$.notes[*].id", "notes__id", "TAG"),
            ("$.address[*].id", "address__id", "TAG"),
            ("$.address[*].city", "address__city", "TAG"),
            ("$.address[*].postalCode", "address__postalCode", "TAG"),
            ("$.address[*].note.id", "address__note__id", "TAG"),
            ("$.address[*].note.description", "address__note__description", "TEXT"),
        ]
        for (field, fieldAttr, fieldType) in expected {
            #expect(
                fields.contains(where: { $0.0 == field && $0.1 == fieldAttr && $0.2 == fieldType }))
        }
    }

    /// Helper to inspect Index by name
    func inspectIndex(name: String) async throws -> [(String, String, String)] {
        let infoResponse = try await self.poolService.leaseConnection { connection in
            connection.send(
                command: "FT.INFO", with: [.bulkString(ByteBuffer(string: name))]
            )
        }.get()

        let infoArray = try #require(infoResponse.array)

        // locate "attributes"
        var attributes: [RESPValue]?
        var i = 0
        while i < infoArray.count {
            if infoArray[i].string == "attributes" {
                attributes = infoArray[i + 1].array
                break
            }
            i += 2
        }

        let attrs = try #require(attributes)

        // Each entry is"attributes", [
        //    [ "identifier", "$.id", "attribute", "id", "type", "TAG" ],
        //    [ "identifier", "$.name", "attribute", "name", "type", "TAG" ],
        //    ...
        let fields: [(String, String, String)] = attrs.compactMap { entryValue in
            guard let entry = entryValue.array else { return nil }
            var identifier: String?
            var attribute: String?
            var type: String?

            var j = 0
            while j < entry.count {
                switch entry[j].string {
                case "identifier":
                    identifier = entry[j + 1].string
                case "attribute":
                    attribute = entry[j + 1].string
                case "type":
                    type = entry[j + 1].string
                default:
                    break
                }
                j += 2  // advance by pairs
            }

            if let id = identifier, let attr = attribute, let t = type {
                return (id, attr, t)
            }
            return nil
        }

        return fields
    }
}
