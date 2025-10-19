@preconcurrency import RediStack

/// Thread safe singleton reference for shared redis connection pool service
public enum SharedPoolHelper {
    private static let sharedPool = SharedPool()

    public static func set(poolService: RedisConnectionPoolService) async {
        await sharedPool.set(poolService)
    }

    public static func shared() async -> RedisConnectionPoolService {
        await sharedPool.get()
    }
}

actor SharedPool {
    private var poolService: RedisConnectionPoolService?

    func set(_ poolService: RedisConnectionPoolService) {
        self.poolService = poolService
    }

    func get() -> RedisConnectionPoolService {
        guard let poolService = self.poolService else {
            fatalError("RedisOM not configured.")
        }
        return poolService
    }
}
