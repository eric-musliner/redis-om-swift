import Foundation

///
///
public func == <Model, T: CustomStringConvertible>(
    lhs: KeyPath<Model, T>,
    rhs: T
) -> Predicate<Model> {
    Predicate {
        let fieldName = Model.key(for: lhs)  // Map KeyPath -> schema field name
        let indexType = Model.indexType(for: lhs)

        guard let indexType else {
            throw QueryBuilderError.fieldNotIndexed(field: fieldName)
        }

        switch indexType {
        case .tag:
            let escapedRhs = escapeTagValue(rhs.description)
            return "(@\(fieldName):{\(escapedRhs)})"
        case .numeric:
            return "@\(fieldName):[\(rhs) \(rhs)]"
        case .text, .geo, .vector:
            return "@\(fieldName):(\(rhs))"

        }
    }
}

/// Handle Optional Generic Types
///
public func == <Model, T: CustomStringConvertible>(
    lhs: KeyPath<Model, T?>,
    rhs: T
) -> Predicate<Model> {
    Predicate {
        let fieldName = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard let indexType else {
            throw QueryBuilderError.fieldNotIndexed(field: fieldName)
        }

        switch indexType {
        case .tag:
            let escapedRhs = escapeTagValue(rhs.description)
            return "(@\(fieldName):{\(escapedRhs)})"
        case .numeric:
            return "@\(fieldName):[\(rhs) \(rhs)]"
        case .text, .geo, .vector:
            return "@\(fieldName):(\(rhs))"
        }
    }
}

/// Handle Date Type
///
public func == <Model>(
    lhs: KeyPath<Model, Date?>,
    rhs: Date
) -> Predicate<Model> {
    Predicate {
        let fieldName = Model.key(for: lhs)
        let indexType = Model.indexType(for: lhs)

        guard let indexType else {
            throw QueryBuilderError.fieldNotIndexed(field: fieldName)
        }

        guard indexType == .numeric else {
            throw QueryBuilderError.invalidType(
                field: fieldName, actual: indexType.rawValue, expected: "numeric for Date")
        }

        // default Date encoding behavior from JSONEncoder
        let timestamp = rhs.timeIntervalSinceReferenceDate
        return "@\(fieldName):[\(timestamp) \(timestamp)]"
    }
}

///
///
public func > <Model>(
    lhs: KeyPath<Model, Int>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        return "@\(field):[\(rhs + 1) +inf]"
    }
}

///
///
public func > <Model>(
    lhs: KeyPath<Model, Int?>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        return "@\(field):[\(rhs + 1) +inf]"
    }
}

///
///
public func < <Model>(
    lhs: KeyPath<Model, Int>,
    rhs: Int
) -> Predicate<Model> {
    Predicate {
        let field = Model.key(for: lhs)
        return "@\(field):[-inf \(rhs - 1)]"
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
