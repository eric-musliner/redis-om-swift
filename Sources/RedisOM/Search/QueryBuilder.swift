import Foundation
import NIOCore
@preconcurrency import RediStack

/// A  query builder for constructing and executing Redis Search queries
/// against models conforming to ``JsonModel``.
///
/// `QueryBuilder` provides a type-safe API for building complex search
/// expressions using Swift key paths and operator overloads:
///
/// ```swift
/// let query = try await User.find()
///     .where(\.age > 30)
///     .and(\.name == "Alice")
///     .or(\.$role ~= ["admin", "moderator"])
///     .limit(0..<10)
///     .execute()
/// ```
///
/// Internally, it translates predicates into Redis Search syntax
/// (`FT.SEARCH`) and decodes results back into model instances.
/// The builder supports chaining filters, combining predicates
/// with logical `AND`/`OR`
///
/// - Note: `execute()` is asynchronous and will send the constructed query
///   to Redis using the shared connection pool.
public struct QueryBuilder<Model: JsonModel> {
    private var predicate: Predicate<Model>?
    private var range: Range<Int>?

    public init() {}

    /// Adds a `WHERE` clause to the query with the given predicate, replacing any
    /// existing predicate on this builder.
    ///
    /// - Parameter predicate: A `Predicate<Model>` that defines the condition to apply.
    /// - Returns: A new `QueryBuilder` instance with the applied `WHERE` clause.
    /// - Throws: Rethrows any error from building the predicate.
    ///
    /// Example:
    /// ```swift
    /// let query = try User.query()
    ///     .where(\.$age >= 18)
    /// ```
    public func `where`(_ predicate: Predicate<Model>) throws -> Self {
        var copy = self
        copy.predicate = predicate
        return copy
    }

    /// Combines the existing query predicate with the given predicate using a
    /// logical `AND`. If no predicate exists yet, this acts like `where`.
    ///
    /// - Parameter predicate: A `Predicate<Model>` to combine with the existing one.
    /// - Returns: A new `QueryBuilder` instance with the combined `AND` condition.
    /// - Throws: Rethrows any error from building the predicate.
    ///
    /// Example:
    /// ```swift
    /// let query = try User.query()
    ///     .where(\.$isActive == true)
    ///     .and(\.$age >= 18)
    /// ```
    public func and(_ predicate: Predicate<Model>) throws -> Self {
        var copy = self
        if let existing = copy.predicate {
            copy.predicate = existing.and(predicate)
        } else {
            copy.predicate = predicate
        }
        return copy
    }

    /// Combines the existing query predicate with the given predicate using a
    /// logical `OR`. If no predicate exists yet, this acts like `where`.
    ///
    /// - Parameter predicate: A `Predicate<Model>` to combine with the existing one.
    /// - Returns: A new `QueryBuilder` instance with the combined `OR` condition.
    /// - Throws: Rethrows any error from building the predicate.
    ///
    /// Example:
    /// ```swift
    /// let query = try User.query()
    ///     .where(\.$role == "admin")
    ///     .or(\.$role == "moderator")
    /// ```
    public func or(_ predicate: Predicate<Model>) throws -> Self {
        var copy = self
        if let existing = copy.predicate {
            copy.predicate = existing.or(predicate)
        } else {
            copy.predicate = predicate
        }
        return copy
    }

    ///
    ///
    public func limit(_ range: Range<Int>) -> Self {
        var copy = self
        copy.range = range
        return copy
    }

    func buildQuery() throws -> String {
        guard let predicate else { return "*" }  // match all
        return try predicate.render()
    }

    /// Execute RedisSearch query against db and serialize result
    ///
    /// Ex:
    ///
    ///  [
    ///   1,                            # total matches
    ///   "user:123",             # the document key
    ///   [ "id", "123", "name", "Alice", "age", "30" ]   # flat array of fields
    ///  ]
    public func execute() async throws -> [Model] {
        let query: String
        query = try buildQuery()

        let limitClause = range.map { "LIMIT \($0.lowerBound) \($0.count)" } ?? ""
        let cmd = ["FT.SEARCH", Model.indexName, query, limitClause].filter { !$0.isEmpty }

        print(query)
        print(Array(query.utf8))
        let resp = try await SharedPoolHelper.shared().send(
            command: cmd[0],
            with: cmd.dropFirst().map { RESPValue.bulkString(ByteBuffer(string: $0)) }
        ).get()

        guard case .array(let items) = resp else {
            throw RedisError(reason: "Unexpected RESP type from FT.SEARCH")
        }
        guard items.count > 1 else { return [] }

        // Skip total hits at index 0
        let rows = items.dropFirst()
        var models: [Model] = []

        // [
        //  1,                      # total matches
        //  "user:123",             # the document key
        //  [ "id", "123", "name", "Alice", "age", "30" ]   # flat array of fields
        // ]
        for i in stride(from: 1, to: rows.count, by: 2) {
            guard i + 1 <= rows.count else { break }

            // Document fields array
            guard case .array(let fieldItems) = rows[i + 1] else { continue }

            var dict: [String: String] = [:]
            for j in stride(from: 0, to: fieldItems.count, by: 2) {
                guard j + 1 < fieldItems.count,
                    case .bulkString(let kBufOpt) = fieldItems[j],
                    case .bulkString(let vBufOpt) = fieldItems[j + 1],
                    let kBuf = kBufOpt,
                    let vBuf = vBufOpt,
                    let k = kBuf.getString(at: 0, length: kBuf.readableBytes),
                    let v = vBuf.getString(at: 0, length: vBuf.readableBytes)
                else { continue }
                dict[k] = v
            }

            guard let jsonString = dict["$"] else {
                throw RedisError(reason: "Missing JSON payload for key \(rows[i])")
            }

            guard let jsonData = jsonString.data(using: .utf8) else {
                throw RedisError(reason: "Unable to convert JSON string to data: \(jsonString)")
            }

            do {
                let model = try JSONDecoder().decode(Model.self, from: jsonData)
                models.append(model)
            } catch {
                throw RedisError(
                    reason:
                        "Failed to decode model \(Model.self) from JSON: \(error.localizedDescription)"
                )
            }

        }

        return models
    }
}
