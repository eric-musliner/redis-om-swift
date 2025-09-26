import Foundation
import RedisOMCore

/// A protocol for types that can be converted into a RedisSearch-compatible
/// string value, depending on the field’s index type.
///
/// Conforming types must implement `asRedisSearchValue(for:)`, which renders
/// the value into the correct query syntax for the given `IndexType`.
///
/// For example:
/// - `String` values can be used with `.tag` or `.text` fields. Tag values
///   are escaped to handle spaces and special characters, while text values
///   are passed through directly.
/// - `Int`, `Double`, and `Float` are only valid for `.numeric` fields and
///   are converted to their string form.
/// - `Date` is supported as `.numeric` by matching `JSONEncoder`’s default
///   behavior (seconds since the reference date).
///
/// If the value is used with an incompatible index type, a
/// `QueryBuilderError.invalidType` will be thrown.
public protocol RedisSearchRepresentable {
    /// Converts the conforming value into a string suitable for use in a
    /// RedisSearch query for the given index type.
    ///
    /// - Parameter indexType: The type of index this field is stored under.
    /// - Returns: A `String` representation suitable for RedisSearch syntax.
    /// - Throws: `QueryBuilderError.invalidType` if the value cannot be
    ///   represented under the given `indexType`.
    func asRedisSearchValue(for indexType: IndexType) throws -> String
}

extension String: RedisSearchRepresentable {
    public func asRedisSearchValue(for indexType: IndexType) throws -> String {
        switch indexType {
        case .tag: return escapeTagValue(self)
        case .text: return self
        default:
            throw QueryBuilderError.invalidType(
                field: "?", actual: indexType.rawValue, expected: "text")
        }
    }
}

extension Int: RedisSearchRepresentable {
    public func asRedisSearchValue(for indexType: IndexType) throws -> String {
        guard indexType == .numeric else {
            throw QueryBuilderError.invalidType(
                field: "?", actual: indexType.rawValue, expected: "numeric")
        }
        return String(self)
    }
}

extension Double: RedisSearchRepresentable {
    public func asRedisSearchValue(for indexType: IndexType) throws -> String {
        guard indexType == .numeric else {
            throw QueryBuilderError.invalidType(
                field: "?", actual: indexType.rawValue, expected: "numeric")
        }
        return String(self)
    }
}

extension Float: RedisSearchRepresentable {
    public func asRedisSearchValue(for indexType: IndexType) throws -> String {
        guard indexType == .numeric else {
            throw QueryBuilderError.invalidType(
                field: "?", actual: indexType.rawValue, expected: "numeric")
        }
        return String(self)
    }
}

extension Date: RedisSearchRepresentable {
    public func asRedisSearchValue(for indexType: IndexType) throws -> String {
        guard indexType == .numeric else {
            throw QueryBuilderError.invalidType(
                field: "?", actual: indexType.rawValue, expected: "numeric")
        }
        // Match JSONEncoder's default behavior
        return String(self.timeIntervalSinceReferenceDate)
    }
}

/// Escape special characters in tag based querry string values
/// Ex:
/// alice\@example\.com
///
/// - Parameters:
///    - value: query value to escape
/// - Returns: escaped tag string value
private func escapeTagValue(_ value: String) -> String {
    // Escape special characters for RediSearch TAG fields
    var escaped = value
    let specialChars: [Character] = [
        "{", "}", "[", "]", "<", ">", "|", "(", ")", "\"", "'", "@", "#", "$", "%", "^", "&",
        "*", "(", ")", "-", "+", "=", "~", ".", ",", ":", ";",
    ]
    for ch in specialChars {
        escaped = escaped.replacingOccurrences(of: String(ch), with: "\\\(ch)")
    }
    return escaped
}
