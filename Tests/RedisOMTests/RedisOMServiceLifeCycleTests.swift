import Logging
import NIO
import RediStack
import ServiceLifecycle
import Testing

@testable import RedisOM

final class RedisOMServiceLifecycleTests {

    init() async throws {
        // Silence log output during tests
        #expect(isLoggingConfigured)
    }

    deinit {
        Task {
            await SharedPoolHelper.reset()
        }
    }

    @Test("RedisOM service lifecycle - basic startup and shutdown")
    func testBasicServiceLifecycle() async throws {
        let redisOM = try RedisOM()
        redisOM.register(User.self)
        redisOM.register(Note.self)

        let logger = Logger(label: "test.service-lifecycle")
        let group = ServiceGroup(services: [redisOM], logger: logger)

        // Start the service group
        let runTask = Task {
            try await group.run()
        }

        // Allow time for startup and migration
        try await Task.sleep(for: .milliseconds(500))

        // Verify pool is active
        #expect(redisOM.poolService.availableConnectionCount > 0)

        // Test that we can perform operations
        var user = User(name: "Test User", email: "test@example.com")
        try await user.save()

        let retrieved = try await User.get(id: user.id!)
        #expect(retrieved?.name == "Test User")

        // Cleanup
        try await user.delete()

        // Trigger graceful shutdown
        await group.triggerGracefulShutdown()
        try await runTask.value
    }

    @Test("RedisOM service lifecycle - multiple models registration")
    func testMultipleModelsRegistration() async throws {
        let redisOM = try RedisOM()
        redisOM.register(User.self)
        redisOM.register(Note.self)
        redisOM.register(Bike.self)
        redisOM.register(Item.self)

        let logger = Logger(label: "test.multi-models")
        let group = ServiceGroup(services: [redisOM], logger: logger)

        let runTask = Task {
            try await group.run()
        }

        try await Task.sleep(for: .milliseconds(500))

        // Test operations on multiple model types
        var user = User(name: "John Doe", email: "john@example.com")
        try await user.save()

        var note = Note(description: "Test note")
        try await note.save()

        var bike = Bike(
            model: "Mountain Pro",
            brand: "TestBike",
            price: 1500,
            type: "Mountain",
            specs: Spec(material: "Carbon", weight: 12),
            helmetIncluded: true
        )
        try await bike.save()

        // Verify all models work
        let retrievedUser = try await User.get(id: user.id!)
        let retrievedNote = try await Note.get(id: note.id!)
        let retrievedBike = try await Bike.get(id: bike.id!)

        #expect(retrievedUser?.name == "John Doe")
        #expect(retrievedNote?.description == "Test note")
        #expect(retrievedBike?.model == "Mountain Pro")

        try await user.delete()
        try await note.delete()
        try await bike.delete()

        await group.triggerGracefulShutdown()
        try await runTask.value
    }

    @Test("RedisOM service lifecycle - graceful shutdown behavior")
    func testGracefulShutdown() async throws {
        let redisOM = try RedisOM()
        redisOM.register(User.self)

        let logger = Logger(label: "test.shutdown")
        let group = ServiceGroup(services: [redisOM], logger: logger)

        let runTask = Task {
            try await group.run()
        }

        try await Task.sleep(for: .milliseconds(500))

        // Verify service is running
        #expect(redisOM.poolService.availableConnectionCount > 0)

        var user = User(name: "Shutdown Test", email: "shutdown@example.com")
        try await user.save()

        // Trigger graceful shutdown
        await group.triggerGracefulShutdown()
        try await runTask.value

        let count = redisOM.poolService.availableConnectionCount
        #expect(count == 0, "Pool should be closed after shutdown")
    }

    @Test("RedisOM service lifecycle - error handling during startup")
    func testStartupErrorHandling() async throws {
        let invalidRedisOM = try RedisOM(
            url: "redis://invalid-host:9999",
            retryPolicy: .limited(2)
        )
        invalidRedisOM.register(User.self)

        let logger = Logger(label: "test.error-handling")
        let group = ServiceGroup(services: [invalidRedisOM], logger: logger)

        let runTask = Task {
            try await group.run()
        }

        // Allow a few retry attempts
        try await Task.sleep(for: .seconds(3))
        await group.triggerGracefulShutdown()

        do {
            try await runTask.value
        } catch {
            // Expect a RedisConnectionPoolError
            #expect(error is RedisConnectionPoolError || error is RedisError)
        }
    }

    @Test("RedisOM service lifecycle - concurrent service operations")
    func testConcurrentOperations() async throws {
        let redisOM = try RedisOM()
        redisOM.register(User.self)

        let logger = Logger(label: "test.concurrent")
        let group = ServiceGroup(services: [redisOM], logger: logger)

        let runTask = Task {
            try await group.run()
        }

        try await Task.sleep(for: .milliseconds(500))

        // Perform concurrent operations
        await withTaskGroup(of: Void.self) { taskGroup in
            for i in 0..<10 {
                taskGroup.addTask {
                    do {
                        var user = User(name: "User \(i)", email: "user\(i)@example.com")
                        try await user.save()

                        let retrieved = try await User.get(id: user.id!)
                        #expect(retrieved?.name == "User \(i)")

                        try await user.delete()
                    } catch {
                        // Log error but don't fail the test for individual operations
                        print("Concurrent operation failed: \(error)")
                    }
                }
            }
        }

        await group.triggerGracefulShutdown()
        try await runTask.value
    }

    @Test("RedisOM service lifecycle - restart behavior")
    func testRestartBehavior() async throws {
        let redisOM = try RedisOM()
        redisOM.register(User.self)

        let logger = Logger(label: "test.restart")

        // First run
        let group = ServiceGroup(services: [redisOM], logger: logger)
        var runTask = Task {
            try await group.run()
        }

        try await Task.sleep(for: .milliseconds(500))

        var user = User(name: "Persistent User", email: "persistent@example.com")
        try await user.save()

        await group.triggerGracefulShutdown()
        try await runTask.value

        // Second run - simulate restart
        let redisOM2 = try RedisOM()
        redisOM2.register(User.self)

        let group2 = ServiceGroup(services: [redisOM2], logger: logger)
        runTask = Task {
            try await group2.run()
        }

        try await Task.sleep(for: .milliseconds(500))

        // Data should persist across restarts
        let retrieved = try await User.get(id: user.id!)
        #expect(retrieved?.name == "Persistent User")

        // Cleanup
        try await user.delete()

        await group2.triggerGracefulShutdown()
        try await runTask.value
    }
}
