import Foundation
import NIOCore
@preconcurrency import RediStack

// MARK: - RedisModel

/// A protocol representing a persistable model that can be stored and retrieved from Redis.
///
/// `RedisModel` defines a set of behaviors required for types that wish to be persisted in Redis,
/// using a strongly typed `id` and a model-specific key prefix for namespacing.
///
/// Conforming types must be `Codable` and `Sendable`, and provide an optional `id` property,
/// which will be set on creation or by Redis. Keys are constructed as `"\(keyPrefix):\(id)"`
/// .
/// ## Associated Types
/// - `IDType`: The type used for the model's identifier. Must conform to `LosslessStringConvertible`,
///   `Hashable`, and `Sendable`. Commonly `String`, `Int`, or `UUID`.
///
/// ## Requirements:
/// - `id`: An optional identifier used to uniquely store the object in Redis. If not provided,
///   a new ID should be generated during `save()`.
/// - `keyPrefix`: A static prefix used to namespace the model's keys in Redis.
/// - `save()`: Stores the model instance in Redis.
/// - `get(id:)`: Fetches a model instance from Redis by ID.
/// - `delete(using:)`: Removes the model instance from Redis using the provided client.
public protocol RedisModel: Codable, Sendable {
    associatedtype IDType: LosslessStringConvertible & Hashable & Sendable = String

    var id: IDType? { get set }
    static var keyPrefix: String { get }
    static var schema: [Field] { get }

    mutating func save() async throws
    static func get(id: IDType) async throws -> Self?
    func delete() async throws
    static func delete(id: IDType) async throws
}

extension RedisModel {
    static var schema: [Field] { [] }

    public var redisKey: String {
        "\(Self.keyPrefix):\(id ?? UUID().uuidString as! IDType)"
    }

    public static var indexName: String {
        "idx:\(String(describing: self))"
    }

    public func getRedisKey() -> RedisKey {
        return RedisKey(self.redisKey)
    }
}
