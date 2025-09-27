public struct Predicate<Model: JsonModel> {
    private let renderClosure: () throws -> String

    init(_ render: @escaping () throws -> String) {
        self.renderClosure = render
    }

    func render() throws -> String {
        try renderClosure()
    }
}

extension Predicate {
    public func and(_ other: Predicate<Model>) -> Predicate<Model> {
        Predicate {
            "(\(try self.render()) \(try other.render()))"
        }
    }

    public func or(_ other: Predicate<Model>) -> Predicate<Model> {
        Predicate {
            "(\(try self.render()) | \(try other.render()))"
        }
    }

    public func not() -> Predicate<Model> {
        Predicate {
            "(-\(try self.render()))"
        }
    }
}

//public struct Predicate<Model: JsonModel> {
//    private let renderClosure: () throws -> String
//
//    init(_ render: @escaping () throws -> String) {
//        self.renderClosure = render
//    }
//
//    func render() throws -> String {
//        try renderClosure()
//    }
//}
