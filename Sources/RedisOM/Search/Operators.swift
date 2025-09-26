import Foundation

/// Builds a RedisSearch equality predicate for a non-optional indexed field.
///
/// Depending on the index type, this operator renders differently:
/// - **Tag fields**: `(@field:{value})`
/// - **Numeric fields**: `@field:[value value]` (exact match range)
/// - **Text/Geo/Vector fields**: `@field:(value)`
///
/// - Parameters:
///   - lhs: A key path to the indexed field on the model.
///   - rhs: The value to compare against, convertible to a RedisSearch representation.
/// - Returns: A `Predicate<Model>` that can be combined into a query.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed,
///           or an error if the value cannot be converted for the index type.
public func == <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T>,
    rhs: T
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard let indexType else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        let rendered = try rhs.asRedisSearchValue(for: indexType)

        switch indexType {
        case .tag: return "(@\(field):{\(rendered)})"
        case .numeric: return "@\(field):[\(rendered) \(rendered)]"
        case .text, .geo, .vector: return "@\(field):(\(rendered))"
        }
    }
}

/// Builds a RedisSearch equality predicate for an optional indexed field.
///
/// Depending on the index type, this operator renders differently:
/// - **Tag fields**: `(@field:{value})`
/// - **Numeric fields**: `@field:[value value]` (exact match range)
/// - **Text/Geo/Vector fields**: `@field:(value)`
///
/// This overload supports fields declared as optional in the model but
/// still indexed in RedisSearch.
///
/// - Parameters:
///   - lhs: A key path to the optional indexed field on the model.
///   - rhs: The value to compare against, convertible to a RedisSearch representation.
/// - Returns: A `Predicate<Model>` that can be combined into a query.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed,
///           or an error if the value cannot be converted for the index type.
public func == <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T?>,
    rhs: T
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard let indexType else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        let rendered = try rhs.asRedisSearchValue(for: indexType)

        switch indexType {
        case .tag: return "(@\(field):{\(rendered)})"
        case .numeric: return "@\(field):[\(rendered) \(rendered)]"
        case .text, .geo, .vector: return "@\(field):(\(rendered))"
        }
    }
}

/// Builds a RedisSearch inequality predicate for a non-optional indexed field.
///
/// Depending on the index type, this operator renders differently:
/// - **Tag fields**: `(@field:{value})`
/// - **Numeric fields**: `@field:[value value]` (exact match range)
/// - **Text/Geo/Vector fields**: `@field:(value)`
///
/// This overload supports fields declared as optional in the model but
/// still indexed in RedisSearch.
///
/// - Parameters:
///   - lhs: A key path to the non-optional indexed field on the model.
///   - rhs: The value to compare against, convertible to a RedisSearch representation.
/// - Returns: A `Predicate<Model>` that can be combined into a query.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed,
///           or an error if the value cannot be converted for the index type.
public func != <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T>,
    rhs: T
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard let indexType else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        let rendered = try rhs.asRedisSearchValue(for: indexType)

        switch indexType {
        case .tag: return "-(@\(field):{\(rendered)})"
        case .numeric: return "-@\(field):[\(rendered) \(rendered)]"
        case .text, .geo, .vector: return "-@\(field):(\(rendered))"
        }
    }
}

/// Builds a RedisSearch inequality predicate for an optional indexed field.
///
/// Depending on the index type, this operator renders differently:
/// - **Tag fields**: `(@field:{value})`
/// - **Numeric fields**: `@field:[value value]` (exact match range)
/// - **Text/Geo/Vector fields**: `@field:(value)`
///
/// This overload supports fields declared as optional in the model but
/// still indexed in RedisSearch.
///
/// - Parameters:
///   - lhs: A key path to the optional indexed field on the model.
///   - rhs: The value to compare against, convertible to a RedisSearch representation.
/// - Returns: A `Predicate<Model>` that can be combined into a query.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed,
///           or an error if the value cannot be converted for the index type.
public func != <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T?>,
    rhs: T
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard let indexType else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        let rendered = try rhs.asRedisSearchValue(for: indexType)

        switch indexType {
        case .tag: return "-(@\(field):{\(rendered)})"
        case .numeric: return "-@\(field):[\(rendered) \(rendered)]"
        case .text, .geo, .vector: return "-@\(field):(\(rendered))"
        }
    }
}

/// Builds a RedisSearch range query (greather than equal to) for a non-optional fiield
///
/// - Parameters:
///   - lhs: A key path to the non-optional indexed field on the model.
///   - rhs: The lower bound (inclusive) value to compare against.
/// - Returns: A `Predicate<Model>` representing the `>=` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func >= <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard indexType != nil else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        return "@\(field):[\(rhs) +inf]"
    }
}

/// Builds a RedisSearch range query (greather than equal to) for an optional fiield
///
/// - Parameters:
///   - lhs: A key path to the optional indexed field on the model.
///   - rhs: The lower bound (inclusive) value to compare against.
/// - Returns: A `Predicate<Model>` representing the `>=` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func >= <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T?>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard indexType != nil else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        return "@\(field):[\(rhs) +inf]"
    }
}

/// Builds a RedisSearch range query (greather than) for a non-optional fiield
///
/// - Parameters:
///   - lhs: A key path to the non-optional indexed field on the model.
///   - rhs: The lower bound (inclusive) value to compare against.
/// - Returns: A `Predicate<Model>` representing the `>=` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func > <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard indexType != nil else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        return "@\(field):[\(rhs + 1) +inf]"
    }
}

/// Builds a RedisSearch range query (greather than) for an optional fiield
///
/// - Parameters:
///   - lhs: A key path to the optional indexed field on the model.
///   - rhs: The lower bound (inclusive) value to compare against.
/// - Returns: A `Predicate<Model>` representing the `>=` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func > <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T?>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard indexType != nil else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        return "@\(field):[\(rhs + 1) +inf]"
    }
}

/// Builds a RedisSearch range query (less than equal to) for a non-optional fiield
///
/// - Parameters:
///   - lhs: A key path to the non-optional indexed field on the model.
///   - rhs: The lower bound (inclusive) value to compare against.
/// - Returns: A `Predicate<Model>` representing the `>=` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func <= <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard indexType != nil else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        return "@\(field):[-inf \(rhs)]"
    }
}

/// Builds a RedisSearch range query (less than equal to) for an optional fiield
///
/// - Parameters:
///   - lhs: A key path to the optional indexed field on the model.
///   - rhs: The lower bound (inclusive) value to compare against.
/// - Returns: A `Predicate<Model>` representing the `>=` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func <= <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T?>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard indexType != nil else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        return "@\(field):[-inf \(rhs)]"
    }
}

/// Builds a RedisSearch range query (less than) for a non-optional fiield
///
/// - Parameters:
///   - lhs: A key path to the non-optional indexed field on the model.
///   - rhs: The lower bound (inclusive) value to compare against.
/// - Returns: A `Predicate<Model>` representing the `>=` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func < <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard indexType != nil else {
            throw QueryBuilderError.fieldNotIndexed(field: field)
        }

        return "@\(field):[-inf \(rhs - 1)]"
    }
}

/// Builds a RedisSearch range query (less than equal to) for an optional fiield
///
/// - Parameters:
///   - lhs: A key path to the optional indexed field on the model.
///   - rhs: The lower bound (inclusive) value to compare against.
/// - Returns: A `Predicate<Model>` representing the `>=` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func < <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T?>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let fieldName = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard indexType != nil else {
            throw QueryBuilderError.fieldNotIndexed(field: fieldName)
        }

        return "@\(fieldName):[-inf \(rhs - 1)]"
    }
}

/// Builds a RedisSearch range query for a non-optional field that matches documents where the field's value
/// lies between the given lower and upper bounds (inclusive).
///
/// - Parameters:
///   - lhs: A key path to the non-optional field on the model to compare.
///   - rhs: A tuple `(lower, upper)` specifying the inclusive range bounds.
/// - Returns: A `Predicate<Model>` representing the `BETWEEN` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func ... <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T>,
    rhs: (T, T)
) -> Predicate<Model> {
    Predicate {
        let fieldName = Model.key(for: lhs)
        guard let indexType = Model.indexType(for: lhs) else {
            throw QueryBuilderError.fieldNotIndexed(field: fieldName)
        }

        let lower = try rhs.0.asRedisSearchValue(for: indexType)
        let upper = try rhs.1.asRedisSearchValue(for: indexType)
        return "@\(fieldName):[\(lower) \(upper)]"
    }
}

/// Builds a RedisSearch range query for an optional field that matches documents where the field's value
/// lies between the given lower and upper bounds (inclusive).
///
/// - Parameters:
///   - lhs: A key path to the optional field on the model to compare.
///   - rhs: A tuple `(lower, upper)` specifying the inclusive range bounds.
/// - Returns: A `Predicate<Model>` representing the `BETWEEN` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func ... <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T?>,
    rhs: (T, T)
) -> Predicate<Model> {
    Predicate {
        let fieldName = Model.key(for: lhs)
        guard let indexType = Model.indexType(for: lhs) else {
            throw QueryBuilderError.fieldNotIndexed(field: fieldName)
        }

        let lower = try rhs.0.asRedisSearchValue(for: indexType)
        let upper = try rhs.1.asRedisSearchValue(for: indexType)
        return "@\(fieldName):[\(lower) \(upper)]"
    }
}

/// Builds a RedisSearch query for a non-optional field that matches documents where the field's value
/// is contained in the provided set of options.
///
/// - Parameters:
///   - lhs: A key path to the non-optional field on the model to compare.
///   - rhs: An array of values to match against.
/// - Returns: A `Predicate<Model>` representing the `IN` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func ~= <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T>,
    rhs: [T]
) -> Predicate<Model> {
    Predicate {
        let fieldName = Model.key(for: lhs)
        guard let indexType = Model.indexType(for: lhs) else {
            throw QueryBuilderError.fieldNotIndexed(field: fieldName)
        }

        let renderedValues = try rhs.map { try $0.asRedisSearchValue(for: indexType) }

        switch indexType {
        case .tag:
            // Tag index supports `{val1|val2|val3}`
            return "@\(fieldName):{\(renderedValues.joined(separator: "|"))}"
        case .numeric:
            // RedisSearch has no native multi-match numeric syntax, so OR together exact ranges
            let clauses = renderedValues.map { "@\(fieldName):[\($0) \($0)]" }
            return "(\(clauses.joined(separator: " | ")))"
        case .text, .geo, .vector:
            // match text terms
            let clauses = renderedValues.map { "@\(fieldName):(\($0))" }
            return "(\(clauses.joined(separator: " | ")))"
        }
    }
}

/// Builds a RedisSearch query for an ptional field that matches documents where the field's value
/// is contained in the provided set of options.
///
/// - Parameters:
///   - lhs: A key path to the optional field on the model to compare.
///   - rhs: An array of values to match against.
/// - Returns: A `Predicate<Model>` representing the `IN` condition.
/// - Throws: `QueryBuilderError.fieldNotIndexed` if the field is not indexed for search.
public func ~= <Model, T: RedisSearchRepresentable>(
    lhs: KeyPath<Model, T?>,
    rhs: [T]
) -> Predicate<Model> {
    Predicate {
        let fieldName = Model.key(for: lhs)
        guard let indexType = Model.indexType(for: lhs) else {
            throw QueryBuilderError.fieldNotIndexed(field: fieldName)
        }

        let renderedValues = try rhs.map { try $0.asRedisSearchValue(for: indexType) }

        switch indexType {
        case .tag:
            // Tag index supports `{val1|val2|val3}`
            return "@\(fieldName):{\(renderedValues.joined(separator: "|"))}"
        case .numeric:
            // RedisSearch has no native multi-match numeric syntax, so OR exact ranges
            let clauses = renderedValues.map { "@\(fieldName):[\($0) \($0)]" }
            return "(\(clauses.joined(separator: " | ")))"
        case .text, .geo, .vector:
            // OR match text terms
            let clauses = renderedValues.map { "@\(fieldName):(\($0))" }
            return "(\(clauses.joined(separator: " | ")))"
        }
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
