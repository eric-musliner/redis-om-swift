enum QueryBuilderError: Error, CustomStringConvertible {
    case fieldNotIndexed(field: String)
    case invalidType(field: String, actual: String, expected: String)

    var description: String {
        switch self {
        case .fieldNotIndexed(let field):
            return "Tried to query on non-indexed field: \(field)"
        case .invalidType(let field, let actual, let expected):
            return "Invalid index type \(actual) for field: \(field), expected: \(expected)"
        }

    }
}
