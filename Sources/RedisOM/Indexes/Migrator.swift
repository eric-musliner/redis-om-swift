import Logging
import NIOCore
@preconcurrency import RediStack

/// The `Migrator` is responsible for managing Redis Search indexes that correspond
/// to your `JsonModel` types.
///
/// It uses the `schema` definitions emitted by the `@Model` macro to:
///   - Generate Redis Search field mappings (`FT.CREATE`) from model fields
///   - Flatten nested models into dot-notation (e.g., `notes.id`)
///   - Resolve JSONPath selectors based on container type:
///       • Arrays → `$.notes[*].id`
///       • Dictionaries → `$.notes.*.id`
///   - Apply the correct Redis index type (`.text`, `.numeric`, `.tag`, etc.)
///
/// The migrator ensures that your Redis index definitions stay in sync with
/// your Swift model declarations. If a model changes, re-running the migrator
/// will update the corresponding Redis index.
///
/// Example usage:
///
/// ```swift
/// try await Migrator(redis: client, logger: .init(label: "Test").migrate([User.self])
/// ```
///
/// This will:
///   1. Inspect `Spec.schema`
///   2. Create (or update) the Redis Search index for `Spec`
///   3. Register all nested fields according to their container semantics.
///
/// By centralizing index generation in the `Migrator`, your application code
/// can query Redis Search directly without worrying about JSONPath differences
/// between arrays and dictionaries.
public struct Migrator {
    let client: RedisClient
    let logger: Logger

    /// Apply indexes for models to Redis. Drops index if it already exists so the index reflects latest
    ///   - Parameters
    ///    - models: array of RedisModels
    func migrate(models: [any RedisModel.Type]) async throws {
        for model in models {
            let indexName = model.indexName

            // Always drop index if it exists. Keep existing documents
            let listResponse = try await client.send(command: "FT._LIST").get()
            let indexNames = listResponse.array?.compactMap({ $0.string })

            if indexNames!.contains(indexName) {
                _ = try await client.send(
                    command: "FT.DROPINDEX",
                    with: [.bulkString(ByteBuffer(string: indexName))]
                ).get()
                logger.info("Dropped index \(indexName)")
            } else {
                logger.info("Index \(indexName) does not exist yet — skipping drop")
            }

            // Create new index
            var args: [RESPValue] = [
                .bulkString(ByteBuffer(string: indexName)),
                .bulkString(ByteBuffer(string: "ON")),
                .bulkString(ByteBuffer(string: "JSON")),
                .bulkString(ByteBuffer(string: "PREFIX")),
                .bulkString(ByteBuffer(string: "1")),
                .bulkString(ByteBuffer(string: "\(model.keyPrefix):")),
                .bulkString(ByteBuffer(string: "SCHEMA")),
            ]

            for field in model.schema {
                args.append(.bulkString(ByteBuffer(string: "$.\(field.name)")))
                args.append(.bulkString(ByteBuffer(string: "AS")))
                args.append(.bulkString(ByteBuffer(string: field.name.redisAlias())))
                args.append(.bulkString(ByteBuffer(string: field.indexType.rawValue)))
            }

            _ = client.send(command: "FT.CREATE", with: args)
            logger.info("Created index \(indexName) for model \(model)")

        }
    }

}

/// Returns a Redis-safe alias for use in RediSearch schema definitions.
///
/// Redis does not allow field names in `FT.SEARCH` queries to contain
/// certain characters (such as dots `.` or JSONPath operators like `[*]`).
/// This helper normalizes a JSONPath-style field name into a query-safe alias
/// by applying the following rules:
///
/// - `.` is replaced with `__`
/// - `[*]` is stripped (array flattening handled by JSONPath itself)
///
/// For example:
///
/// ```swift
/// "address.city".redisAlias()         // "address__city"
/// "notes[*].description".redisAlias() // "notes__description"
/// ```
extension String {
    func redisAlias() -> String {
        // replace disallowed chars (dot, brackets) with underscores
        return
            self
            .replacingOccurrences(of: ".", with: "__")
            .replacingOccurrences(of: "[*]", with: "")
    }
}
