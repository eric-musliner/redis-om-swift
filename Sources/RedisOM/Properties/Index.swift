import RedisOMCore

@propertyWrapper
public struct Index<Value: Codable & Sendable>: Codable, Sendable {
    public var wrappedValue: Value
    public var indexType: IndexType

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        self.indexType = .text
    }

    public init(wrappedValue: Value, type indexType: IndexType = .tag) {
        self.indexType = indexType
        self.wrappedValue = wrappedValue
    }

    // Metadata-only initializer
    public init(type indexType: IndexType) {
        self.indexType = indexType
        if let empty = [] as? Value {
            self.wrappedValue = empty
        } else if let empty = "" as? Value {
            self.wrappedValue = empty
        } else {
            fatalError(
                "Metadata-only initializer called at runtime for non-emptyable type \(Value.self)")
        }
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
