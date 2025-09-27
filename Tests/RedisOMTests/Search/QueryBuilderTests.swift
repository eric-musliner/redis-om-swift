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
        // Silence log output during tests
        #expect(isLoggingConfigured)

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
    func testFindSingleWherePredicateTextStringNeq() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date(),
        )
        try await user.save()

        // FT.SEARCH 'idx:User' '-@name:(Alice)'
        let users: [User] = try await User.find().where(\.name != "Bill").execute()
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
    func testFindMultipleAndPredicateStrEqNeq() async throws {
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
            \.email != "alice@example.com"
        ).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice.wonder@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
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

    @Test
    func testFindSingleWherePredicateNumericGt() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()

        var user2: User = User(
            name: "Bill",
            email: "bill@example.com",
            aliases: ["Robert", "Billy"],
            age: 55,
            createdAt: now,
        )
        try await user2.save()
        // FT.SEARCH 'idx:User' '(@createdAt:[1758570669.819691 1758570669.819691])'
        let users: [User] = try await User.find().where(\.age > 50).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Bill")
        #expect(users[0].email == "bill@example.com")
        #expect(users[0].aliases == ["Robert", "Billy"])
        #expect(users[0].age == 55)
    }

    @Test
    func testFindSingleWherePredicateNumericLt() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()

        var user2: User = User(
            name: "Bill",
            email: "bill@example.com",
            aliases: ["Robert", "Billy"],
            age: 55,
            createdAt: now,
        )
        try await user2.save()
        // FT.SEARCH 'idx:User' '(@createdAt:[1758570669.819691 1758570669.819691])'
        let users: [User] = try await User.find().where(\.age < 50).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    @Test
    func testFindAndWherePredicateNumericLt() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()

        var user2: User = User(
            name: "Bill",
            email: "bill@example.com",
            aliases: ["Robert", "Billy"],
            age: 55,
            createdAt: now,
        )
        try await user2.save()
        // FT.SEARCH 'idx:User' '(@createdAt:[1758570669.819691 1758570669.819691])'
        let users: [User] = try await User.find().where(\.name == "Bill").and(\.age < 60).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Bill")
        #expect(users[0].email == "bill@example.com")
        #expect(users[0].aliases == ["Robert", "Billy"])
        #expect(users[0].age == 55)
    }

    @Test
    func testFindSingleWherePredicateNumericLte() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()

        var user2: User = User(
            name: "Bill",
            email: "bill@example.com",
            aliases: ["Robert", "Billy"],
            age: 55,
            createdAt: now,
        )
        try await user2.save()
        // FT.SEARCH 'idx:User' '@age:[-inf 33]'
        let users: [User] = try await User.find().where(\.age <= 33).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    @Test
    func testFindAndWherePredicateNumericLte() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()

        var user2: User = User(
            name: "Bill",
            email: "bill@example.com",
            aliases: ["Robert", "Billy"],
            age: 55,
            createdAt: now,
        )
        try await user2.save()
        // FT.SEARCH 'idx:User' '(@age:[-inf 55] @name:(Alice))'
        let users: [User] = try await User.find().where(\.age <= 55).and(\.name == "Alice")
            .execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    @Test
    func testFindSingleWherePredicateNumericGte() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()

        var user2: User = User(
            name: "Bill",
            email: "bill@example.com",
            aliases: ["Robert", "Billy"],
            age: 55,
            createdAt: now,
        )
        try await user2.save()
        // FT.SEARCH 'idx:User' '@age:[33 +inf]'
        let users: [User] = try await User.find().where(\.age >= 33).execute()
        try #require(!users.isEmpty)
        #expect(users.count == 2)
        for user in users {
            if user.name == "Alice" {
                #expect(user.name == "Alice")
                #expect(user.email == "alice@example.com")
                #expect(user.aliases == ["Alicia", "alice"])
                #expect(user.age == 33)
            } else if user.name == "Bill" {
                #expect(user.name == "Bill")
                #expect(user.email == "bill@example.com")
                #expect(user.aliases == ["Robert", "Billy"])
                #expect(user.age == 55)
            }
        }
    }

    @Test
    func testFindAndWherePredicateNumericGte() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()

        var user2: User = User(
            name: "Bill",
            email: "bill@example.com",
            aliases: ["Robert", "Billy"],
            age: 55,
            createdAt: now,
        )
        try await user2.save()
        // FT.SEARCH 'idx:User' '(@age:[10 +inf] @name:(Alice))'
        let users: [User] = try await User.find().where(\.age >= 10).and(\.name == "Alice")
            .execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    @Test
    func testFindAndWherePredicateNumericBetween() async throws {
        try await self.migrator.migrate(models: [User.self])

        let now = Date()
        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: now,
        )
        try await user.save()

        var user2: User = User(
            name: "Bill",
            email: "bill@example.com",
            aliases: ["Robert", "Billy"],
            age: 55,
            createdAt: now,
        )
        try await user2.save()

        var user3: User = User(
            name: "Bill",
            email: "billy@mail.com",
            aliases: ["Robert", "Billy"],
            age: 70,
            createdAt: now,
        )
        try await user3.save()
        // FT.SEARCH 'idx:User' '(@age:[34 60] @name:(Bill))'
        let users: [User] = try await User.find().where(\.age...(34, 60)).and(\.name == "Bill")
            .execute()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Bill")
        #expect(users[0].email == "bill@example.com")
        #expect(users[0].aliases == ["Robert", "Billy"])
        #expect(users[0].age == 55)
    }

    @Test
    func testFindAndWherePredicateNumericBetweenDouble() async throws {
        try await self.migrator.migrate(models: [Item.self])

        var item: Item = Item(
            price: 24.99,
            name: "Gloves"
        )
        try await item.save()

        var item2: Item = Item(
            price: 50.99,
            name: "Helmet"
        )
        try await item2.save()

        var item3: Item = Item(
            price: 65.99,
            name: "Helmet NIPS"
        )
        try await item3.save()

        // FT.SEARCH 'idx:Item' '@price:[33.0 60.0]'
        let items: [Item] = try await Item.find().where(\.price...(33.0, 60.0)).execute()
        try #require(!items.isEmpty)
        #expect(items.count == 1)
        #expect(items[0].name == "Helmet")
        #expect(items[0].price == 50.99)
    }

    @Test
    func testFindAndWherePredicateNumericIn() async throws {
        try await self.migrator.migrate(models: [Item.self])

        var item: Item = Item(
            price: 24.99,
            name: "Gloves"
        )
        try await item.save()

        var item2: Item = Item(
            price: 50.99,
            name: "Helmet"
        )
        try await item2.save()

        var item3: Item = Item(
            price: 65.99,
            name: "Helmet NIPS"
        )
        try await item3.save()

        // FT.SEARCH 'idx:Item' '(@price:[24.99 24.99] | @price:[50.99 50.99])'
        let items: [Item] = try await Item.find().where(\.price ~= [24.99, 50.99]).execute()
        try #require(!items.isEmpty)
        #expect(items.count == 2)
        for item in items {
            if item.name == "Gloves" {
                #expect(item.name == "Gloves")
                #expect(item.price == 24.99)
            } else if item.name == "Helmet" {
                #expect(item.name == "Helmet")
                #expect(item.price == 50.99)
            }
        }
    }

    @Test
    func testFindAndWherePredicateStringIn() async throws {
        try await self.migrator.migrate(models: [Item.self])

        var item: Item = Item(
            price: 24.99,
            name: "Gloves"
        )
        try await item.save()

        var item2: Item = Item(
            price: 50.99,
            name: "Helmet"
        )
        try await item2.save()

        var item3: Item = Item(
            price: 65.99,
            name: "Helmet NIPS"
        )
        try await item3.save()

        // FT.SEARCH 'idx:Item' '@name:{Gloves|Helmet}'
        let items: [Item] = try await Item.find().where(\.name ~= ["Gloves", "Helmet"]).execute()
        try #require(!items.isEmpty)
        #expect(items.count == 2)
        for item in items {
            if item.name == "Gloves" {
                #expect(item.name == "Gloves")
                #expect(item.price == 24.99)
            } else if item.name == "Helmet" {
                #expect(item.name == "Helmet")
                #expect(item.price == 50.99)
            }
        }

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
    func testFindMultipleSeparateOrPredicateStrNeq() async throws {
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
        let users: [User] = try await User.find().where(\.name == "Alice").or(\.name == "Bob").or(
            \.name != "Charlie"
        )
        .execute()

        try #require(!users.isEmpty)
        #expect(users.count == 3)
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
            } else if user.name == "Sally" {
                #expect(user.name == "Sally")
                #expect(user.email == "sally@example.com")
                #expect(user.aliases == [])
                #expect(user.age == 60)
            }
        }
    }

    @Test
    func testFindMultipleSeparateOrPredicateStrEq() async throws {
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
        let users: [User] = try await User.find().where(\.name == "Alice").or(\.name == "Bob").or(
            \.name == "Sally"
        )
        .execute()

        try #require(!users.isEmpty)
        #expect(users.count == 3)
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
            } else if user.name == "Sally" {
                #expect(user.name == "Sally")
                #expect(user.email == "sally@example.com")
                #expect(user.aliases == [])
                #expect(user.age == 60)
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
