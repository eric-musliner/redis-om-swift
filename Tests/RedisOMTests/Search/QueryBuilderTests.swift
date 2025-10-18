import Foundation
@preconcurrency import RediStack
import Testing

@testable import RedisOM

// MARK: QueryBuilder Test Suite
@Suite("QueryBuilderTests")
final class QueryBuilderTests {

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
        self.migrator = Migrator(
            client: self.poolService, logger: .init(label: "QueryBuilderTests"))
    }

    deinit {
        Task {
            let poolService = await SharedPoolHelper.shared()
            _ = try await poolService.leaseConnection { connection in
                connection.send(command: "FLUSHALL")
            }.get()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").all()
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
        let users: [User] = try await User.find().where(\.$name != "Bill").all()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").all()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").and(
            \.$email == "alice@example.com"
        ).all()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").and(
            \.$email != "alice@example.com"
        ).all()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").and(
            \.$email == "alice@example.com"
        ).all()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").and(
            \.$age == 45
        ).all()
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
        let items: [Item] = try await Item.find().where(\.$name == "Winter Parka").and(
            \.$price == 24.99
        ).all()
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
        let users: [User] = try await User.find().where(\.$createdAt == now).all()
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
        let users: [User] = try await User.find().where(\.$age > 50).all()
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
        let users: [User] = try await User.find().where(\.$age < 50).all()
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
        let users: [User] = try await User.find().where(\.$name == "Bill").and(\.$age < 60)
            .all()
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
        let users: [User] = try await User.find().where(\.$age <= 33).all()
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
        let users: [User] = try await User.find().where(\.$age <= 55).and(\.$name == "Alice")
            .all()
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
        let users: [User] = try await User.find().where(\.$age >= 33).all()
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
        let users: [User] = try await User.find().where(\.$age >= 10).and(\.$name == "Alice")
            .all()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 33)
    }

    @Test
    func testFindAndWherePredicateDoubleGte() async throws {
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

        // FT.SEARCH 'idx:Item' '@price:[65.99 +inf]'
        let items: [Item] = try await Item.find().where(\.$price >= 65.99).all()
        try #require(!items.isEmpty)
        #expect(items.count == 1)
        #expect(items[0].name == "Helmet NIPS")
        #expect(items[0].price == 65.99)
    }

    @Test
    func testFindAndWherePredicateDoubleGtEdge() async throws {
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
        let items: [Item] = try await Item.find().where(\.$price > 24.99).all()
        try #require(!items.isEmpty)
        #expect(items.count == 2)
        for item in items {
            if item.name == "Helmet" {
                #expect(item.name == "Helmet")
                #expect(item.price == 50.99)
            } else if item.name == "Helmet NIPS" {
                #expect(item.name == "Helmet NIPS")
                #expect(item.price == 65.99)
            }
        }
    }

    @Test
    func testFindAndWherePredicateDoubleLtEdge() async throws {
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

        // FT.SEARCH 'idx:Item' '@price:[-inf (65.99]'
        let items: [Item] = try await Item.find().where(\.$price < 65.99).all()
        try #require(!items.isEmpty)
        #expect(items.count == 2)
        for item in items {
            if item.name == "Helmet" {
                #expect(item.name == "Helmet")
                #expect(item.price == 50.99)
            } else if item.name == "Gloves" {
                #expect(item.name == "Gloves")
                #expect(item.price == 24.99)
            }
        }
    }

    @Test
    func testFindAndWherePredicateDoubleLteEdge() async throws {
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

        // FT.SEARCH 'idx:Item' '@price:[-inf 65.99]'
        let items: [Item] = try await Item.find().where(\.$price <= 65.99).all()
        try #require(!items.isEmpty)
        #expect(items.count == 3)
        for item in items {
            if item.name == "Helmet" {
                #expect(item.name == "Helmet")
                #expect(item.price == 50.99)
            } else if item.name == "Helmet NIPS" {
                #expect(item.name == "Helmet NIPS")
                #expect(item.price == 65.99)
            } else if item.name == "Gloves" {
                #expect(item.name == "Gloves")
                #expect(item.price == 24.99)
            }
        }
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
        let users: [User] = try await User.find().where(\.$age...(34, 60)).and(\.$name == "Bill")
            .all()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Bill")
        #expect(users[0].email == "bill@example.com")
        #expect(users[0].aliases == ["Robert", "Billy"])
        #expect(users[0].age == 55)
    }

    @Test
    func testFindAndWherePredicateNumericBetweenDoubleInclusiveEdge() async throws {
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
        let items: [Item] = try await Item.find().where(\.$price...(24.99, 60.0)).all()
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
        let items: [Item] = try await Item.find().where(\.$price ~= [24.99, 50.99]).all()
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
        let items: [Item] = try await Item.find().where(\.$name ~= ["Gloves", "Helmet"]).all()
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
            let _: [Author] = try await Author.find().where(\.$createdAt == now).all()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").and(\.$age > 40)
            .all()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").or(\.$name == "Bob")
            .all()

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
        let users: [User] = try await User.find().where(\.$name == "Alice").or(\.$name == "Bob").or(
            \.$name != "Charlie"
        )
        .all()

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
        let users: [User] = try await User.find().where(\.$name == "Alice").or(\.$name == "Bob").or(
            \.$name == "Sally"
        )
        .all()

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
        let users: [User] = try await User.find().where(\.$name == "Alice").or(\.$age == 22)
            .all()
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
        let users: [User] = try await User.find().where(\.$name == "Alice").or(\.$name == "Sandra")
            .and(\.$age == 33)
            .all()
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

    // MARK: Nested

    @Test
    func testFindAndPredicateNested() async throws {
        try await self.migrator.migrate(models: [Person.self])

        var person: Person = Person(
            name: "Alice",
            email: "alice@example.com",
            address: Address(
                addressLine1: "123 South Main St", city: "Pittsburg", state: "PA",
                country: "US", postalCode: "15120"
            ),
            age: 45,
            createdAt: Date()
        )
        try await person.save()

        var person2: Person = Person(
            name: "Alice",
            email: "alice.wonder@example.com",
            address: Address(
                addressLine1: "123 Winding Hill", city: "Scottsdale", state: "AZ",
                country: "US", postalCode: "85250"
            ),
            age: 33,
            createdAt: Date()
        )
        try await person2.save()

        // FT.SEARCH idx:Person "@name:{Alice} @address__city:{Pittsburg}"
        let persons: [Person] = try await Person.find().where(\.$name == "Alice").and(
            \.$address.$city == "Pittsburg"
        ).all()
        try #require(!persons.isEmpty)
        #expect(persons.count == 1)
        #expect(persons[0].name == "Alice")
        #expect(persons[0].email == "alice@example.com")
        #expect(persons[0].age == 45)
    }

    @Test
    func testFindAndPredicateDeepNested() async throws {
        try await self.migrator.migrate(models: [Person.self])

        var person: Person = Person(
            name: "Alice",
            email: "alice@example.com",
            address: Address(
                addressLine1: "123 South Main St", city: "Pittsburg", state: "PA",
                country: "US", postalCode: "15120"
            ),
            age: 45,
            createdAt: Date()
        )
        try await person.save()

        var person2: Person = Person(
            name: "Alice",
            email: "alice.wonder@example.com",
            address: Address(
                addressLine1: "123 Winding Hill", city: "Scottsdale", state: "AZ",
                country: "US", postalCode: "85250", note: Note(description: "mailing address")
            ),
            age: 33,
            createdAt: Date()
        )
        try await person2.save()

        // FT.SEARCH idx:Person "((@name:{Alice}) @address__note__description:(mailing address))
        let persons: [Person] = try await Person.find().where(\.$name == "Alice").and(
            \.$address.$note.$description == "mailing address"
        ).all()
        try #require(!persons.isEmpty)
        #expect(persons.count == 1)
        #expect(persons[0].name == "Alice")
        #expect(persons[0].email == "alice.wonder@example.com")
        #expect(persons[0].age == 33)
    }

    @Test
    func testFindAndPredicateNestedCollection() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 45,
            address: [
                Address(
                    addressLine1: "123 South Main St", city: "Pittsburg", state: "PA",
                    country: "US", postalCode: "15120"
                )
            ],
            createdAt: Date()
        )
        try await user.save()

        var user2: User = User(
            name: "Alice",
            email: "alice.wonder@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date()
        )
        try await user2.save()

        // FT.SEARCH 'idx:User' '(@name:(Alice) (@address__city:{Pittsburg}))''
        let users: [User] = try await User.find().where(\.$name == "Alice").and(
            \.$address[\.$city] == "Pittsburg"
        ).all()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 45)
    }

    @Test
    func testFindAndPredicateNestedCollectionMultiple() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 45,
            address: [
                Address(
                    addressLine1: "123 South Main St", city: "Pittsburg", state: "PA",
                    country: "US", postalCode: "15120"
                ),
                Address(
                    addressLine1: "5678 Broadway", city: "New York", state: "NY",
                    country: "US", postalCode: "15120"
                ),
            ],
            createdAt: Date()
        )
        try await user.save()

        var user2: User = User(
            name: "Alice",
            email: "alice.wonder@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date()
        )
        try await user2.save()

        // FT.SEARCH 'idx:User' '(@name:(Alice) (@address__city:{New York}))''
        let users: [User] = try await User.find().where(\.$name == "Alice").and(
            \.$address[\.$city] == "New York"
        ).all()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 45)
    }

    @Test
    func testFindAndPredicateDeepNestedCollectionAttribute() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 45,
            address: [
                Address(
                    addressLine1: "123 South Main St", city: "Pittsburg", state: "PA",
                    country: "US", postalCode: "15120"
                ),
                Address(
                    addressLine1: "5678 Broadway", city: "New York", state: "NY",
                    country: "US", postalCode: "15120", note: Note(description: "business address")
                ),
            ],
            createdAt: Date()
        )
        try await user.save()

        var user2: User = User(
            name: "Alice",
            email: "alice.wonder@example.com",
            aliases: ["Alicia", "alice"],
            age: 33,
            createdAt: Date()
        )
        try await user2.save()

        // FT.SEARCH 'idx:User' '(@name:(Alice) @address__note__description:(business address))'
        let users: [User] = try await User.find().where(\.$name == "Alice").and(
            \.$address[\.$note.$description] == "business address"
        ).all()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 45)
    }

    @Test
    func testFindAndPredicateStringInArray() async throws {
        try await self.migrator.migrate(models: [User.self])

        var user: User = User(
            name: "Alice",
            email: "alice@example.com",
            aliases: ["Alicia", "alice"],
            age: 45,
            address: [
                Address(
                    addressLine1: "123 South Main St", city: "Pittsburg", state: "PA",
                    country: "US", postalCode: "15120"
                ),
                Address(
                    addressLine1: "5678 Broadway", city: "New York", state: "NY",
                    country: "US", postalCode: "15120", note: Note(description: "business address")
                ),
            ],
            createdAt: Date()
        )
        try await user.save()

        var user2: User = User(
            name: "Alice",
            email: "alice.wonder@example.com",
            age: 33,
            createdAt: Date()
        )
        try await user2.save()

        // FT.SEARCH 'idx:User' '(@name:(Alice) (@aliases:{Alicia}))'
        let users: [User] = try await User.find().where(\.$name == "Alice").and(
            \.$aliases ~= "Alicia"
        ).all()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
        #expect(users[0].email == "alice@example.com")
        #expect(users[0].aliases == ["Alicia", "alice"])
        #expect(users[0].age == 45)
    }

    // MARK: Execute Variants
    @Test
    func testFindFirst() async throws {
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

        // ["FT.SEARCH", "idx:Item", "@price:[(24.0 (70.0]", "LIMIT", "0", "1"]
        let result: Item? = try await Item.find().where(\.$price...(24.00, 70.0)).first()

        let resultItem: Item = try #require(result)
        #expect(resultItem.name == "Gloves")
        #expect(resultItem.price == 24.99)
    }

    @Test
    func testFindwithLimit() async throws {
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

        // ["FT.SEARCH", "idx:Item", "@price:[(24.0 (70.0]", "LIMIT", "0", "2"]
        let items = try await Item.find().where(\.$price...(24.00, 70.0)).limit(0..<2).all()
        try #require(!items.isEmpty)
        #expect(items.count == 2)
    }

    @Test
    func testExistsTrue() async throws {
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

        // ["FT.SEARCH", "idx:Item", "@price:[-inf 65.99]", "LIMIT", "0", "1"]
        let exists = try await Item.find().where(\.$price <= 65.99).exists()
        #expect(exists == true)
    }

    @Test
    func testExistsFalse() async throws {
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

        // ["FT.SEARCH", "idx:Item", "@price:[(65.99 +inf]", "LIMIT", "0", "1"]
        let exists = try await Item.find().where(\.$price > 65.99).exists()
        #expect(exists == false)
    }

    // MARK: NOT
    @Test
    func testFindNotMultipleOrPredicateStrIntEq() async throws {
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

        // FT.SEARCH idx:User '["FT.SEARCH", "idx:User", "(-@name:(Alice))"]'
        let users: [User] = try await User.find().where(\.$name == "Alice").not()
            .all()
        try #require(!users.isEmpty)
        #expect(users.count == 2)
        for user in users {
            if user.name == "Sally" {
                #expect(user.name == "Sally")
                #expect(user.email == "sally@example.com")
                #expect(user.aliases == [])
                #expect(user.age == 60)
            } else if user.name == "Bob" {
                #expect(user.name == "Bob")
                #expect(user.email == "bob.smith@example.com")
                #expect(user.aliases == ["Bill", "Robert"])
                #expect(user.age == 22)
            }
        }
    }

    @Test
    func testFindNotAndWherePredicateNumericLte() async throws {
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
        let users: [User] = try await User.find().where(\.$age <= 33).and(\.$name == "Alice")
            .not().all()
        try #require(!users.isEmpty)
        #expect(users.count == 1)
        #expect(users[0].name == "Bill")
        #expect(users[0].email == "bill@example.com")
        #expect(users[0].aliases == ["Robert", "Billy"])
        #expect(users[0].age == 55)
    }

}
