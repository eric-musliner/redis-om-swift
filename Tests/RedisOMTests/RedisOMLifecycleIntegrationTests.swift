import Logging
import NIO
import RediStack
import ServiceLifecycle
import Testing
import Vapor

@testable import RedisOM

final class RedisOMLifecycleIntegrationTests {

    init() async throws {
        // Silence log output during tests
        #expect(isLoggingConfigured)
    }

    deinit {
        Task {
            await SharedPoolHelper.reset()
        }
    }

    @Test("RedisOM lifecycle - Service and LifecycleHandler compatibility")
    func testServiceAndLifecycleHandlerCompatibility() async throws {
        // Test that the same RedisOM instance can work with both lifecycle systems
        let redisOM = try RedisOM()
        redisOM.register(User.self)
        redisOM.register(Note.self)

        let logger = Logger(label: "test.integration")

        // Use as Service with ServiceLifecycle
        let serviceGroup = ServiceGroup(services: [redisOM], logger: logger)
        let serviceTask = Task {
            try await serviceGroup.run()
        }

        await redisOM.waitUntilReady()

        // Verify service is working
        var serviceUser = User(name: "Service User", email: "service@test.com")
        try await serviceUser.save()

        let retrievedServiceUser = try await User.get(id: serviceUser.id!)
        #expect(retrievedServiceUser?.name == "Service User")

        try await serviceUser.delete()

        // Shutdown service
        await serviceGroup.triggerGracefulShutdown()
        try await serviceTask.value

        // Use the same type as LifecycleHandler with Vapor
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let redisOM2 = try RedisOM()
        redisOM2.register(User.self)
        redisOM2.register(Note.self)

        app.lifecycle.use(redisOM2)

        try redisOM2.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))
        try redisOM2.didBoot(app)
        try await Task.sleep(for: .milliseconds(500))

        await redisOM2.waitUntilReady()

        // Verify Vapor lifecycle is working
        var vaporUser = User(name: "Vapor User", email: "vapor@test.com")
        try await vaporUser.save()

        let retrievedVaporUser = try await User.get(id: vaporUser.id!)
        #expect(retrievedVaporUser?.name == "Vapor User")

        try await vaporUser.delete()
        await redisOM2.shutdownAsync(app)
    }

    @Test("RedisOM lifecycle - concurrent Service and Vapor usage")
    func testConcurrentServiceAndVaporUsage() async throws {
        // This tests running Service and Vapor lifecycles concurrently
        // (though in practice this might not be a common use case)

        let serviceRedisOM = try RedisOM()
        serviceRedisOM.register(User.self)

        let vaporRedisOM = try RedisOM()
        vaporRedisOM.register(Note.self)

        let logger = Logger(label: "test.concurrent")

        // Start Service lifecycle
        let serviceGroup = ServiceGroup(services: [serviceRedisOM], logger: logger)
        let serviceTask = Task {
            try await serviceGroup.run()
        }
        await serviceRedisOM.waitUntilReady()

        // Start Vapor lifecycle
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        app.lifecycle.use(vaporRedisOM)

        try vaporRedisOM.willBoot(app)
        try vaporRedisOM.didBoot(app)

        await vaporRedisOM.waitUntilReady()

        // Test operations on both
        await withTaskGroup(of: Void.self) { taskGroup in
            // Service operations
            taskGroup.addTask {
                do {
                    var user = User(
                        name: "Service Concurrent", email: "service.concurrent@test.com")
                    try await user.save()
                    let retrieved = try await User.get(id: user.id!)
                    #expect(retrieved?.name == "Service Concurrent")
                    try await user.delete()
                } catch {
                    print("Service operation failed: \\(error)")
                }
            }

            // Vapor operations
            taskGroup.addTask {
                do {
                    var note = Note(description: "Vapor concurrent note")
                    try await note.save()
                    let retrieved = try await Note.get(id: note.id!)
                    #expect(retrieved?.description == "Vapor concurrent note")
                    try await note.delete()
                } catch {
                    print("Vapor operation failed: \\(error)")
                }
            }
        }

        // Cleanup
        await serviceGroup.triggerGracefulShutdown()
        try await serviceTask.value

        await vaporRedisOM.shutdownAsync(app)
    }

    @Test("RedisOM lifecycle - migration consistency across lifecycle types")
    func testMigrationConsistencyAcrossLifecycleTypes() async throws {
        // Test that migrations work consistently regardless of lifecycle system used

        // Phase 1: Use Service lifecycle to create indexes
        let serviceRedisOM = try RedisOM()
        serviceRedisOM.register(Bike.self)
        serviceRedisOM.register(Spec.self)

        let logger = Logger(label: "test.migration-consistency")
        let serviceGroup = ServiceGroup(services: [serviceRedisOM], logger: logger)

        let serviceTask = Task {
            try await serviceGroup.run()
        }

        try await Task.sleep(for: .milliseconds(500))

        // Create data using Service lifecycle
        var bike = Bike(
            model: "Migration Test Bike",
            brand: "TestBrand",
            price: 1000,
            type: "Hybrid",
            specs: Spec(material: "Steel", weight: 20),
            helmetIncluded: true
        )
        try await bike.save()

        await serviceGroup.triggerGracefulShutdown()
        try await serviceTask.value

        // Phase 2: Use Vapor lifecycle to verify indexes and data persist
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let vaporRedisOM = try RedisOM()
        vaporRedisOM.register(Bike.self)
        vaporRedisOM.register(Spec.self)

        app.lifecycle.use(vaporRedisOM)

        try vaporRedisOM.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))
        try vaporRedisOM.didBoot(app)

        await vaporRedisOM.waitUntilReady()

        // Verify data created by Service lifecycle is accessible via Vapor lifecycle
        let retrievedBike = try await Bike.get(id: bike.id!)
        #expect(retrievedBike?.model == "Migration Test Bike")
        #expect(retrievedBike?.specs.material == "Steel")

        // Cleanup
        try await bike.delete()
        await vaporRedisOM.shutdownAsync(app)
    }

    @Test("RedisOM lifecycle - error resilience across lifecycle systems")
    func testErrorResilienceAcrossLifecycleSystems() async throws {
        // Test that both lifecycle systems handle errors gracefully

        let logger = Logger(label: "test.error-resilience")

        // Service with invalid config
        do {
            let invalidServiceRedisOM = try RedisOM(
                url: "redis://invalid-service-host:9999", retryPolicy: .limited(2))
            invalidServiceRedisOM.register(User.self)

            let serviceGroup = ServiceGroup(services: [invalidServiceRedisOM], logger: logger)
            let serviceTask = Task {
                try await serviceGroup.run()
            }

            try await Task.sleep(for: .milliseconds(500))
            await serviceGroup.triggerGracefulShutdown()

            // Should handle gracefully
            do {
                try await serviceTask.value
            } catch {
                // Connection errors are expected
                #expect(error is RedisConnectionPoolError || error is RedisError)
            }
        }

        // Vapor with invalid config
        do {
            let app = try await Application.make(.testing)
            defer { Task { try await app.asyncShutdown() } }

            let invalidVaporRedisOM = try RedisOM(
                url: "redis://invalid-vapor-host:9999", retryPolicy: .limited(2))
            invalidVaporRedisOM.register(User.self)

            app.lifecycle.use(invalidVaporRedisOM)

            // Should not throw during lifecycle methods
            try invalidVaporRedisOM.willBoot(app)
            try invalidVaporRedisOM.didBoot(app)
            await invalidVaporRedisOM.shutdownAsync(app)
        }
    }

    @Test("RedisOM lifecycle - performance comparison")
    func testPerformanceComparison() async throws {
        let iterationCount = 1000
        let logger = Logger(label: "test.performance")

        // --- Service lifecycle ---
        let serviceStart = Date()
        let serviceRedisOM = try RedisOM()
        serviceRedisOM.register(User.self)

        let group = ServiceGroup(services: [serviceRedisOM], logger: logger)
        let task = Task { try await group.run() }
        await serviceRedisOM.waitUntilReady()

        for i in 0..<iterationCount {
            var user = User(name: "Service Perf User \(i)", email: "service.perf\(i)@test.com")
            try await user.save()
            try await user.delete()
        }

        try await Task.sleep(for: .milliseconds(200))  // ensure flush

        await group.triggerGracefulShutdown()
        try await task.value
        let serviceDuration = Date().timeIntervalSince(serviceStart)

        // --- Vapor lifecycle ---
        let vaporStart = Date()
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        let vaporRedisOM = try RedisOM()
        vaporRedisOM.register(User.self)
        app.lifecycle.use(vaporRedisOM)

        try vaporRedisOM.willBoot(app)
        try await Task.sleep(for: .milliseconds(500))
        try vaporRedisOM.didBoot(app)

        await vaporRedisOM.waitUntilReady()

        for i in 0..<iterationCount {
            var user = User(name: "Vapor Perf User \(i)", email: "vapor.perf\(i)@test.com")
            try await user.save()
            try await user.delete()
        }

        await vaporRedisOM.shutdownAsync(app)
        let vaporDuration = Date().timeIntervalSince(vaporStart)

        let ratio = max(serviceDuration, vaporDuration) / min(serviceDuration, vaporDuration)
        #expect(ratio < 3.0, "Performance difference too high")

        print("Service lifecycle duration: \(serviceDuration)s")
        print("Vapor lifecycle duration: \(vaporDuration)s")
        print("Performance ratio: \(ratio)")
    }
}
