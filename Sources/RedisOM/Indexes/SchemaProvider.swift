protocol _SchemaProvider {
    static var schema: [Field] { get }
}

extension _SchemaProvider {
    static var safeSchema: [Field] { schema }
}

extension Optional where Wrapped == _SchemaProvider.Type {
    var safeSchema: [Field]? { self?.schema }
}
