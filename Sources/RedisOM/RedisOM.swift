@preconcurrency import RediStack

/// Thread safe singleton reference for shared redis connection pool
public enum RedisOM {
    private static let sharedPool = SharedPool()

    public static func set(pool: RedisConnectionPool) async {
        await sharedPool.set(pool)
    }

    public static func shared() async -> RedisConnectionPool {
        await sharedPool.get()
    }
}

actor SharedPool {
    private var pool: RedisConnectionPool?

    func set(_ pool: RedisConnectionPool) {
        self.pool = pool
    }

    func get() -> RedisConnectionPool {
        guard let pool = self.pool else {
            fatalError("RedisOM not configured.")
        }
        return pool
    }
}
