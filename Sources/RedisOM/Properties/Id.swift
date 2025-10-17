import Foundation

/// A property wrapper that designates a field as the model’s unique identifier.
///
/// The `@Id` wrapper marks a property as the primary key for a model conforming
/// to ``JsonModel``. It automatically generates a UUID string when no value is provided,
/// ensuring each instance has a unique identifier.
///
/// The wrapped value is a `String?` to allow flexibility during decoding and initialization,
/// but if the decoded or assigned value is `nil` or empty, a new UUID is generated.
///
/// Example:
/// ```swift
/// struct User: JsonModel {
///     @Id var id: String?
///     @Index var name: String
/// }
///
/// // Automatically generates a UUID:
/// let user = User(name: "Alice")
/// print(user.id!) // "C34F8E3A-9A5F-4E53-9AF7-CC9F1F3EAA56"
///
/// // Decoding JSON with an empty id regenerates a UUID:
/// let decoded = try JSONDecoder().decode(User.self, from: Data(#"{"id": ""}"#.utf8))
/// print(decoded.id!) // new UUID
/// ```
///
/// - Important: This wrapper is automatically recognized by the `@Model` macro
///   and treated as the model’s primary key field in Redis schema generation.
/// - Note: A field marked with this wrapper is automatically also indexed without the need for the Index
///   property wrapper
/// - Note: `Id` conforms to both `Codable` and `Sendable`, and is compatible with
///   Redis persistence and concurrency-safe use cases.
@propertyWrapper
public struct Id: Codable, Sendable {
    public var wrappedValue: String?

    public init(wrappedValue: String? = nil) {
        self.wrappedValue = wrappedValue ?? UUID().uuidString
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try? container.decode(String.self)
        self.wrappedValue = decoded?.isEmpty == false ? decoded! : UUID().uuidString
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
