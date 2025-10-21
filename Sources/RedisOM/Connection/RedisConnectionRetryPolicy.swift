public enum RedisConnectionRetryPolicy: Sendable {
    case never
    case limited(Int)
    case infinite
}
