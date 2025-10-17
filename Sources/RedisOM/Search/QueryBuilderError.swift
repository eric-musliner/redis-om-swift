enum QueryBuilderError: Error, CustomStringConvertible {
    case invalidType(field: String, actual: String, expected: String)

    var description: String {
        switch self {
        case .invalidType(let field, let actual, let expected):
            return "Invalid index type \(actual) for field: \(field), expected: \(expected)"
        }

    }
}
