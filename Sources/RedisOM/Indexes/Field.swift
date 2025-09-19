import RedisOMCore

public struct Field: Sendable {
    public let name: String
    public let type: String
    public let indexType: IndexType?
    public let keyPath: AnyKeyPath
}

extension AnyKeyPath: @unchecked @retroactive Sendable {}
