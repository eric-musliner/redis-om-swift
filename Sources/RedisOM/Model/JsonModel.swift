import Foundation
import NIOCore
@preconcurrency import RediStack
import RedisOMCore

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

    /// Returns a new `QueryBuilder` for this model type.
    ///
    /// Use this method to begin building a query to find instances
    /// of this model in Redis. You can chain additional query methods
    /// on the returned `QueryBuilder`.
    ///
    /// Example:
    /// ```swift
    /// let users = try User.find()
    ///     .where(\.age > 18)
    ///     .all()
    /// ```
    public static func find() -> QueryBuilder<Self> {
        QueryBuilder<Self>()
    }

    /// Returns the schema field name associated with the given key path.
    ///
    /// This function maps a Swift `KeyPath` of the model to the
    /// corresponding field name in the Redis schema. If the key path
    /// does not exist in the schema, it returns `"unknown"`.
    ///
    /// - Parameter kp: A key path to a property on the model.
    /// - Returns: The name of the field in the Redis schema as a `String`.
    static func key<T>(for kp: KeyPath<Self, T>) -> String {
        // Walk schema to find the field name
        schema.first { $0.keyPath == kp }?.name ?? "unknown"
    }

    /// Returns the index type for the given key path, if any.
    ///
    /// This function looks up the index type configured for a
    /// specific model property in the Redis schema. It returns
    /// `nil` if the property is not indexed.
    ///
    /// - Parameter kp: A key path to a property on the model.
    /// - Returns: An optional `IndexType` describing how the field is indexed.
    static func indexType<T>(for kp: KeyPath<Self, T>) -> IndexType? {
        schema.first { $0.keyPath == kp }?.indexType
    }

    /// Persists the current model instance to Redis as JSON.
    ///
    /// This method encodes the model into a JSON string and stores it
    /// under the model's Redis key using the `JSON.SET` command.
    /// It updates the existing entry if it already exists.
    ///
    /// This function is `async` and may throw an error if encoding fails
    /// or if there is an issue communicating with Redis.
    ///
    /// Example:
    /// ```swift
    /// var user = User(name: "Alice", age: 30)
    /// try await user.save()
    /// ```
    ///
    /// - Throws: `RedisError` if the model cannot be encoded to JSON
    ///           or if the Redis command fails.
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

    //// Returns a list of all primary keys for this model in Redis.
    ///
    /// This method scans Redis keys matching the model's key prefix
    /// and extracts the primary key portion of each key. Useful
    /// for enumerating all stored instances.
    ///
    /// - Returns: An array of `IDType` representing all primary keys.
    /// - Throws: `RedisError` if the SCAN command fails or returns an unexpected structure.
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

    /// Retrieves a model instance from Redis by its primary key.
    ///
    /// - Parameter id: The primary key of the model to fetch.
    /// - Returns: The model instance if found, or `nil` if no such key exists.
    /// - Throws: `RedisError` if the key exists but cannot be decoded from JSON.
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

    /// Deletes this model instance from Redis.
    ///
    /// - Throws: `RedisError` if the deletion command fails.
    @inlinable
    public func delete() async throws {
        try await Self.delete(id: self.id!)
    }

    /// Deletes a model from Redis by primary key.
    ///
    /// - Parameter id: The primary key of the model to delete.
    /// - Throws: `RedisError` if the deletion command fails.
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
