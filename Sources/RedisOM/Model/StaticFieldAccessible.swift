/// A protocol that enables type-safe static field access on model types.
///
/// Conforming to `StaticFieldAccessible` allows you to access statically
/// defined field metadata (such as `FieldRef` values) using a key-path
/// subscript syntax:
///
/// ```swift
/// let field = User.self[field: \.$name]
/// print(field.alias) // "name"
/// ```
///
/// This is primarily used by the Redis-OM query builder to resolve
/// `FieldRef` instances from static properties emitted by the `@Model` macro.
/// It enables the query operators (e.g. `==`, `>`, `~=`) to access field
/// metadata such as index type and alias path without needing an instance
/// of the model.
///
/// Example:
/// ```swift
/// struct User: JsonModel {
///     @Index var name: String
///     public static let $name = FieldRef<String>(
///         indexType: .tag,
///         aliasPath: ["name"]
///     )
/// }
///
/// let ref = User.self[field: \.$name]
/// print(ref.alias) // "name"
/// ```
///
/// - Note: This protocol is automatically conformed to by ``JsonModel``
///   and other model types emitted by the `@Model` macro.
public protocol StaticFieldAccessible {
    /// Returns a static field value (e.g. a ``FieldRef``) for the given key path
    /// from the model’s type.
    ///
    /// - Parameter keyPath: A key path that references a static field property.
    /// - Returns: The value of the static field (usually a ``FieldRef``).
    static subscript<Value>(field keyPath: KeyPath<Self.Type, Value>) -> Value { get }
}

extension StaticFieldAccessible {
    /// Default implementation that retrieves a static field value from the
    /// model’s metatype (`Self.Type`) using the given key path.
    public static subscript<Value>(field keyPath: KeyPath<Self.Type, Value>) -> Value {
        Self.self[keyPath: keyPath]
    }
}
