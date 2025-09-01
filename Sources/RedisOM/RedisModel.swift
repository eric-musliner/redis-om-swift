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

    public func getRedisKey() -> RedisKey {
        return RedisKey(self.redisKey)
    }
}

public protocol JsonModel: RedisModel {}

// MARK: - JsonModel
/// `JsonModel`extendsion of RedisModel  behavior using Redis JSON storage.
///
/// Provides a set of convenience methods for saving, retrieving, and deleting models in Redis
/// using `JSON.SET`, `JSON.GET`, and `DEL` commands. Assumes a shared `RedisConnectionPool`
/// has been initialized via `RedisOM.set(pool:)`.
///
/// All models are stored under keys composed as `"\(keyPrefix):\(id)"`, and values are stored
/// as JSON documents at root path `$`.
extension JsonModel {

    /// Save model to Redis
    @inlinable
    public mutating func save() async throws {

        let data = try JSONEncoder().encode(self)

        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw RedisError.init(
                reason: "Unable to serialize data to JSON object."
            )
        }
        let client = await SharedPoolHelper.shared()
        _ = try await client.send(
            command: "JSON.SET",
            with: [
                .bulkString(ByteBuffer(string: redisKey)),
                .bulkString(ByteBuffer(string: "$")),
                .bulkString(ByteBuffer(string: jsonString)),
            ],
        ).get()
    }

    /// Get list of Primary Keys for model in Redis
    /// - Returns:
    ///    - [IDType]: list of primary keys
    @inlinable
    public static func allKeys() async throws -> [IDType] {
        let client = await SharedPoolHelper.shared()
        var cursor = "0"
        var allKeys: [IDType] = []

        repeat {
            let response = try await client.send(
                command: "SCAN",
                with: [
                    .bulkString(ByteBuffer(string: cursor)),
                    .bulkString(ByteBuffer(string: "MATCH")),
                    .bulkString(ByteBuffer(string: "\(keyPrefix):*")),
                    .bulkString(ByteBuffer(string: "COUNT")),
                    .bulkString(ByteBuffer(string: "100")),
                ]
            ).get()

            guard
                let array = response.array,
                array.count == 2,
                let nextCursor = array[0].string,
                let keysArray = array[1].array
            else {
                throw RedisError(reason: "Invalid SCAN response structure")
            }

            cursor = nextCursor
            for keyResp in keysArray {
                if let fullKey = keyResp.string {
                    if let pk = fullKey.split(separator: ":").last {
                        allKeys.append(IDType(String(pk))!)
                    }
                }
            }
        } while cursor != "0"

        return allKeys
    }

    /// Get model by primary key
    /// - Parameters:
    ///    - id: primary key of saved model in Redis
    @inlinable
    public static func get(id: IDType) async throws -> Self? {
        let key = "\(keyPrefix):\(id)"

        let client = await SharedPoolHelper.shared()
        let response = try await client.send(
            command: "JSON.GET",
            with: [.bulkString(ByteBuffer(string: key))]
        ).get()

        guard let string = response.string else {
            return nil
        }
        guard let data = string.data(using: .utf8) else {
            throw RedisError(
                reason: "Unable to deserialize JSON string for \(key)"
            )
        }
        return try JSONDecoder().decode(Self.self, from: data)
    }

    /// Delete model from Redis
    @inlinable
    public func delete() async throws {
        try await Self.delete(id: self.id!)
    }

    /// Delete model from Redis by primary key
    /// - Parameters:
    ///    - id: primary key of the model to delete from Redis
    @inlinable
    public static func delete(id: IDType)
        async throws
    {
        let key = "\(keyPrefix):\(id)"

        let client = await SharedPoolHelper.shared()
        _ = try await client.send(
            command: "JSON.DEL",
            with: [.bulkString(ByteBuffer(string: key))]
        ).get()
    }

}
