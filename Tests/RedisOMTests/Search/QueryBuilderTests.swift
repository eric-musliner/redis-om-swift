import Foundation
@preconcurrency import RediStack
import Testing

@testable import RedisOM

// MARK: QueryBuilder Test Suite
@Suite("QueryBuilderTests")
final class QueryBuilderTests {

    let connectionPool: RedisConnectionPool
    let redisOM: RedisOM
    let migrator: Migrator

    init() async throws {
        self.redisOM = try RedisOM()
        await SharedPoolHelper.set(
            pool: self.redisOM.poolService.connectionPool
        )
        self.connectionPool = await SharedPoolHelper.shared()
        self.migrator = Migrator(
            client: self.connectionPool, logger: .init(label: "QueryBuilderTests"))
    }

    deinit {
        Task {
            let client = await SharedPoolHelper.shared()
            _ = try await client.send(command: "FLUSHALL").get()

        }
    }

    // MARK: AND PREDICATES
    @Test
    func testFindSingleWherePredicateTextStringEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        // FT.SEARCH 'idx:User' '@name:(Alice)'
        let users: [User] = try await User.find().where(\.name == "Alice").execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    @Test
    func testFindSingleWherePredicateTextStringPartialEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice Smith",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        // FT.SEARCH 'idx:User' '@name:(Alice)'
        let users: [User] = try await User.find().where(\.name == "Alice").execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice Smith")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    @Test
    func testFindMultipleAndPredicateStrEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        var user2: User = User(
            name: "Alice",
            email: "alice.wonder@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user2.save()

        // FT.SEARCH idx:User '(@email:{alice\@example\.com}) (@name:{Alice})'
        let users: [User] = try await User.find().where(\.name == "Alice").execute()
        try #require(!users.isEmpty)
        #expect(users.count == 2)
    }

    @Test
    func testFindAndPredicateStrEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        var user2: User = User(
            name: "Alice",
            email: "alice.wonder@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user2.save()

        // FT.SEARCH idx:User '(@email:{alice\@example\.com}) (@name:{Alice})'
        let users: [User] = try await User.find().where(\.name == "Alice").and(
            \.email == "alice@example.com"
        ).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    @Test
    func testFindAndPredicateIntEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 45,
            createdAt: Date(),
        )
        try await user.save()

        var user2: User = User(
            name: "Alice",
            email: "alice.wonder@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user2.save()

        // FT.SEARCH idx:User '(@email:{alice\@example\.com}) (@age:[45 45])'
        let users: [User] = try await User.find().where(\.name == "Alice").and(
            \.age == 45
        ).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 45)
    }

    @Test
    func testFindAndPredicateDoubleEq() async throws {
        try await self.migrator.migrate(models: [Item.self])

        var item: Item = Item(
            price: 24.99,
            name: "Winter Parka"
        )
        try await item.save()

        // FT.SEARCH idx:Item '(@name:{Winter Parka}) @price:[24.99 24.99]'
        let items: [Item] = try await Item.find().where(\.name == "Winter Parka").and(
            \.price == 24.99
        ).execute()
        try #require(!items.isEmpty)
        #expect(items.count == 1)
        #expect(items[0].name == "Winter Parka")
        #expect(items[0].price == 24.99)
    }

    @Test
    func testFindSingleWherePredicateDateEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        print(now)
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()
        // FT.SEARCH 'idx:User' '(@createdAt:[1758570669.819691 1758570669.819691])'
        let users: [User] = try await User.find().where(\.createdAt == now).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    //    @Test
    //    func testFindAndPredicateNested() async throws {
    //        try await self.migrator.migrate(models: [User.self])
    //
    //        var user: User = User(
    //            name: "Alice",
    //            email: "alice@example.com",
    //            aliases: ["Alicia", "alice"],
    //            age: 45,
    //            address: [
    //                Address(
    //                    addressLine1: "123 South Main St", city: "Pittsburg", state: "PA",
    //                    country: "US", postalCode: "15120"
    //                )
    //            ],
    //            createdAt: Date(),
    //        )
    //        try await user.save()
    //
    //        var user2: User = User(
    //            name: "Alice",
    //            email: "alice.wonder@example.com",
    //            aliases: ["Alicia", "alice"],
    //            age: 33,
    //            createdAt: Date(),
    //        )
    //        try await user2.save()
    //
    //        // FT.SEARCH idx:User '(@email:{alice\@example\.com}) (@age:[45 45])'
    //        let users: [User] = try await User.find().where(\.name == "Alice").and(
    //            \.address.city == "Pittsburg"
    //        ).execute()
    //        try #require(!users.isEmpty)
    //        #expect(users.count == 1)
    //        #expect(users[0].name == "Alice")
    //        #expect(users[0].email == "alice@example.com")
    //        #expect(users[0].aliases == ["Alicia", "alice"])
    //        #expect(users[0].age == 45)
    //    }

    @Test
    func testExpectThrowsOnNonIndexedField() async throws {
        try await self.migrator.migrate(models: [Author.self])

        var author: Author = Author(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 45,
            notes: [:],
            createdAt: Date()
        )
        try await author.save()

        await #expect(throws: QueryBuilderError.self) {
            let _: [Author] = try await Author.find().where(\.name == "Alice").and(\.age == 45)
                .execute()
        }
    }

    @Test
    func testExpectThrowsOnWrongIndexForDateField() async throws {
        try await self.migrator.migrate(models: [Author.self])

        let now = Date()
        var author: Author = Author(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 45,
            notes: [:],
            createdAt: Date()
        )
        try await author.save()

        await #expect(throws: QueryBuilderError.self) {
            let _: [Author] = try await Author.find().where(\.createdAt == now).execute()
        }
    }

    @Test
    func testFindAndPredicateStrEqIntGt() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 45,
            createdAt: Date(),
        )
        try await user.save()

        var user2: User = User(
            name: "Alice",
            email: "alice.wonder@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user2.save()

        // FT.SEARCH idx:User '(@name:(Alice) @age:[41 +inf])'
        let users: [User] = try await User.find().where(\.name == "Alice").and(\.age > 40).execute()
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 45)
    }

    // MARK: OR PREDICATES
    @Test
    func testFindMultipleOrPredicateStrEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        var user2: User = User(
            name: "Sally",
            email: "sally@example.com",
            aliases: [],
            age: 60,
            createdAt: Date(),
        )
        try await user2.save()

        var user3: User = User(
            name: "Bob",
            email: "bob.smith@example.com",
            aliases: ["Bill", "Robert"],
            age: 22,
            createdAt: Date(),
        )
        try await user3.save()

        // FT.SEARCH idx:User '(@email:{alice\@example\.com}) (@name:{Alice})'
        let users: [User] = try await User.find().where(\.name == "Alice").or(\.name == "Bob")
            .execute()

        try #require(!users.isEmpty)
        #expect(users.count == 2)
        for user in users {
            if user.name == "Alice" {
                #expect(user.name == "Alice")
                #expect(user.email == "alice@example.com")
                #expect(user.aliases == ["Alicia", "alice"])
                #expect(user.age == 33)
            } else if user.name == "Bob" {
                #expect(user.name == "Bob")
                #expect(user.email == "bob.smith@example.com")
                #expect(user.aliases == ["Bill", "Robert"])
                #expect(user.age == 22)
            }
        }
    }

    @Test
    func testFindMultipleOrPredicateStrIntEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        var user2: User = User(
            name: "Sally",
            email: "sally@example.com",
            aliases: [],
            age: 60,
            createdAt: Date(),
        )
        try await user2.save()

        var user3: User = User(
            name: "Bob",
            email: "bob.smith@example.com",
            aliases: ["Bill", "Robert"],
            age: 22,
            createdAt: Date(),
        )
        try await user3.save()

        // FT.SEARCH idx:User '(@email:{alice\@example\.com}) (@name:{Alice})'
        let users: [User] = try await User.find().where(\.name == "Alice").or(\.age == 22)
            .execute()
        try #require(!users.isEmpty)
        #expect(users.count == 2)
        for user in users {
            if user.name == "Alice" {
                #expect(user.name == "Alice")
                #expect(user.email == "alice@example.com")
                #expect(user.aliases == ["Alicia", "alice"])
                #expect(user.age == 33)
            } else if user.name == "Bob" {
                #expect(user.name == "Bob")
                #expect(user.email == "bob.smith@example.com")
                #expect(user.aliases == ["Bill", "Robert"])
                #expect(user.age == 22)
            }
        }
    }

    // MARK: AND/OR PREDICATES
    @Test
    func testFindMultipleAndOrPredicateStrIntEq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        var user2: User = User(
            name: "Sally",
            email: "sally@example.com",
            aliases: [],
            age: 60,
            createdAt: Date(),
        )
        try await user2.save()

        var user3: User = User(
            name: "Bob",
            email: "bob.smith@example.com",
            aliases: ["Bill", "Robert"],
            age: 22,
            createdAt: Date(),
        )
        try await user3.save()

        var user4: User = User(
            name: "Sandra Smiles",
            email: "sandra.smiles@mail.us",
            aliases: [],
            age: 33,
            createdAt: Date(),
        )
        try await user4.save()

        // FT.SEARCH idx:User '((@name:(Alice) | @name:(Sandra)) @age:[33 33])'
        let users: [User] = try await User.find().where(\.name == "Alice").or(\.name == "Sandra")
            .and(\.age == 33)
            .execute()
        try #require(!users.isEmpty)
        #expect(users.count == 2)
        for user in users {
            if user.name == "Alice" {
                #expect(user.name == "Alice")
                #expect(user.email == "alice@example.com")
                #expect(user.aliases == ["Alicia", "alice"])
                #expect(user.age == 33)
            } else if user.name == "Sandra Smiles" {
                #expect(user.name == "Sandra Smiles")
                #expect(user.email == "sandra.smiles@mail.us")
                #expect(user.aliases == [])
                #expect(user.age == 33)
            }
        }
    }
}
