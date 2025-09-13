import RedisOMCore

@propertyWrapper
public struct Index<Value: Codable & Sendable>: Codable, Sendable {
    public var wrappedValue: Value
    public var indexType: IndexType

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        self.indexType = .text
    }

    public init(wrappedValue: Value, type indexType: IndexType) {
        self.indexType = indexType
        self.wrappedValue = wrappedValue
    }

    // MARK: - Codable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(Value.self)
        self.indexType = .text
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
