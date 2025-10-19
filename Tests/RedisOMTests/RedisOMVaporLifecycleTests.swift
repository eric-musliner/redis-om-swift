import Logging
import NIO
import RediStack
import Testing
import Vapor
import VaporTesting

@testable import RedisOM

// Conform test model to content
extension User: Content {}

@Suite(.serialized)
final class RedisOMVaporLifecycleTests {

    init() async throws {
        // Silence log output during tests
        #expect(isLoggingConfigured)
    }

    deinit {
        Task {
            await SharedPoolHelper.reset()
        }
    }

    @Test("RedisOM Vapor lifecycle - basic willBoot and didBoot")
    func testBasicVaporLifecycle() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let redisOM = try RedisOM()
        redisOM.register(User.self)
        redisOM.register(Note.self)

        app.lifecycle.use(redisOM)

        // Trigger willBoot
        try redisOM.willBoot(app)

        // Allow time for migration
        try await Task.sleep(for: .milliseconds(500))

        // Trigger didBoot
        try redisOM.didBoot(app)

        try await Task.sleep(for: .milliseconds(500))

        // Test that we can perform operations after boot
        var user = User(name: "Vapor Test User", email: "vapor@example.com")
        try await user.save()

        let retrieved = try await User.get(id: user.id!)
        #expect(retrieved?.name == "Vapor Test User")

        // Cleanup
        try await user.delete()

        // Trigger shutdown
        await redisOM.shutdownAsync(app)

    }

    @Test("RedisOM Vapor lifecycle - multiple models with app lifecycle")
    func testMultipleModelsVaporLifecycle() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let redisOM = try RedisOM()
        redisOM.register(User.self)
        redisOM.register(Bike.self)
        redisOM.register(Item.self)
        redisOM.register(Order.self)

        app.lifecycle.use(redisOM)

        // Simulate app boot sequence
        try redisOM.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        try redisOM.didBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        // Test operations on multiple model types
        var user = User(name: "Vapor User", email: "vapor.user@example.com")
        try await user.save()

        var bike = Bike(
            model: "Vapor Bike",
            brand: "TestCycles",
            price: 2000,
            type: "Road",
            specs: Spec(material: "Aluminum", weight: 15),
            helmetIncluded: false
        )
        try await bike.save()

        var item = Item(price: 99.99, name: "Test Item")
        try await item.save()

        var order = Order(items: [item], createdOn: Date())
        try await order.save()

        // Verify all models work
        let retrievedUser = try await User.get(id: user.id!)
        let retrievedBike = try await Bike.get(id: bike.id!)
        let retrievedItem = try await Item.get(id: item.id!)
        let retrievedOrder = try await Order.get(id: order.id!)

        #expect(retrievedUser?.name == "Vapor User")
        #expect(retrievedBike?.model == "Vapor Bike")
        #expect(retrievedItem?.name == "Test Item")
        #expect(retrievedOrder?.items.first?.name == "Test Item")

        // Cleanup
        try await user.delete()
        try await bike.delete()
        try await item.delete()
        try await order.delete()

        // Shutdown
        await redisOM.shutdownAsync(app)
    }

    @Test("RedisOM Vapor lifecycle - error handling during willBoot")
    func testVaporWillBootErrorHandling() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        // Test with invalid Redis configuration
        let invalidRedisOM = try RedisOM(
            url: "redis://nonexistent-host:9999", retryPolicy: .limited(2))
        invalidRedisOM.register(User.self)

        app.lifecycle.use(invalidRedisOM)

        // willBoot should handle connection errors gracefully
        // The method shouldn't throw even if Redis is unavailable
        try invalidRedisOM.willBoot(app)

        // Give time for the connection attempt to fail
        try await Task.sleep(for: .milliseconds(1000))

        // The lifecycle handler should not crash the app even with connection issues
        try invalidRedisOM.didBoot(app)

        await invalidRedisOM.shutdownAsync(app)
    }

    @Test("RedisOM Vapor lifecycle - shutdown behavior")
    func testVaporShutdownBehavior() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let redisOM = try RedisOM()
        redisOM.register(User.self)

        app.lifecycle.use(redisOM)

        // Boot the handler
        try redisOM.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        try redisOM.didBoot(app)
        await redisOM.waitUntilReady()

        // Verify it's working
        #expect(redisOM.poolService.availableConnectionCount > 0)

        var user = User(name: "Shutdown User", email: "shutdown@example.com")
        try await user.save()

        // Test graceful shutdown
        await redisOM.shutdownAsync(app)

        // After shutdown, pool should be closed
        let count = redisOM.poolService.availableConnectionCount
        #expect(count == 0, "Pool should be closed after shutdown")

    }

    @Test("RedisOM Vapor lifecycle - concurrent requests during lifecycle")
    func testConcurrentRequestsDuringLifecycle() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let redisOM = try RedisOM()
        redisOM.register(User.self)

        app.lifecycle.use(redisOM)

        // Boot the handler
        try redisOM.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        try redisOM.didBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        // Simulate concurrent requests
        await withTaskGroup(of: Void.self) { taskGroup in
            for i in 0..<5 {
                taskGroup.addTask {
                    do {
                        var user = User(name: "Concurrent User \(i)", email: "user\(i)@vapor.test")
                        try await user.save()

                        let retrieved = try await User.get(id: user.id!)
                        #expect(retrieved?.name == "Concurrent User \(i)")

                        try await user.delete()
                    } catch {
                        print("Concurrent operation failed: \(error)")
                    }
                }
            }
        }

        await redisOM.shutdownAsync(app)
    }

    @Test("RedisOM Vapor lifecycle - app restart simulation")
    func testVaporAppRestartSimulation() async throws {
        // First app instance
        var app = try await Application.make(.testing)

        let redisOM1 = try RedisOM()
        redisOM1.register(User.self)
        app.lifecycle.use(redisOM1)

        // Boot first instance
        try redisOM1.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))
        try redisOM1.didBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        // Create persistent data
        var user = User(name: "Persistent Vapor User", email: "persistent@vapor.test")
        try await user.save()

        // Shutdown first instance
        try await app.asyncShutdown()

        // Start second app instance (simulating restart)
        app = try await Application.make(.testing)

        let redisOM2 = try RedisOM()
        redisOM2.register(User.self)
        app.lifecycle.use(redisOM2)

        try redisOM2.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))
        try redisOM2.didBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        // Verify data persists across app restarts
        let retrieved = try await User.get(id: user.id!)
        #expect(retrieved?.name == "Persistent Vapor User")

        // Cleanup
        try await user.delete()

        try await app.asyncShutdown()
    }

    @Test("RedisOM Vapor lifecycle - integration with Vapor routes")
    func testVaporRoutesIntegration() async throws {
        let app = try await Application.make(.testing)

        let redisOM = try RedisOM()

        defer {
            Task {
                await redisOM.shutdownAsync(app)

            }
        }

        redisOM.register(User.self)
        app.lifecycle.use(redisOM)

        // Set up routes that use RedisOM
        app.post("users") { req async throws -> User in
            var user = User(name: "Route User", email: "route@vapor.test")
            try await user.save()
            return user
        }

        app.get("users", ":id") { req async throws -> User in
            let id = req.parameters.get("id", as: String.self)!
            return try await User.get(id: id)!
        }

        // Boot the lifecycle
        try redisOM.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))
        try redisOM.didBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        // Test route that creates user
        try await app.test(.POST, "users") { res in
            #expect(res.status == .ok)
        }

        // Create a user to test retrieval
        var testUser = User(name: "Test Route User", email: "test.route@vapor.test")
        try await testUser.save()

        // Test route that retrieves user
        try await app.test(.GET, "users/\(testUser.id!)") { res in
            #expect(res.status == .ok)
        }

        // Cleanup
        try await testUser.delete()
        try await app.asyncShutdown()
    }
}

// Helper extension for async forEach
extension Array {
    fileprivate func asyncForEach(_ operation: (Element) async throws -> Void) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
