///
public protocol StaticFieldAccessible {
    static subscript<Value>(field keyPath: KeyPath<Self.Type, Value>) -> Value { get }
}

extension StaticFieldAccessible {
    public static subscript<Value>(field keyPath: KeyPath<Self.Type, Value>) -> Value {
        Self.self[keyPath: keyPath]
    }
}
