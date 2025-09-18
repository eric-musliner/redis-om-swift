import RedisOMCore

@propertyWrapper
public struct Index<Value: Codable & Sendable>: Codable, Sendable {
    private var storage: Value?
    public var indexType: IndexType

    // Access wrappedValue through storage
    public var wrappedValue: Value {
        get {
            guard let value = storage else {
                fatalError("Index<\(Value.self)> wrappedValue accessed before initialization")
            }
            return value
        }
        set {
            storage = newValue
        }
    }

    // MARK: - Initializers
    public init(wrappedValue: Value) {
        self.indexType = .text
        self.storage = wrappedValue
    }

    public init(wrappedValue: Value, type indexType: IndexType = .tag) {
        self.indexType = indexType
        self.storage = wrappedValue
    }

    /// Metadata-only initializer (no wrapped value set)
    public init(type indexType: IndexType) {
        self.indexType = indexType
        self.storage = nil
    }

    // MARK: - Codable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.storage = try container.decode(Value.self)
        self.indexType = .text
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
