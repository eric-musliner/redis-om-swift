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
    /// Combines this predicate with another using logical `AND`.
    ///
    /// Example:
    /// ```swift
    /// let combined = (\.$age > 30).and(\.$active == true)
    /// // => "(@age:[31 +inf]) (@active:{true})"
    /// ```
    ///
    /// - Parameter other: Another predicate to combine with `AND`.
    /// - Returns: A new predicate representing the conjunction of both.
    public func and(_ other: Predicate<Model>) -> Predicate<Model> {
        Predicate {
            "(\(try self.render()) \(try other.render()))"
        }
    }

    /// Combines this predicate with another using logical `OR`.
    ///
    /// Example:
    /// ```swift
    /// let combined = (\.$city == "Paris").or(\.$city == "Rome")
    /// // => "(@city:{Paris} | @city:{Rome})"
    /// ```
    ///
    /// - Parameter other: Another predicate to combine with `OR`.
    /// - Returns: A new predicate representing the disjunction of both.
    public func or(_ other: Predicate<Model>) -> Predicate<Model> {
        Predicate {
            "(\(try self.render()) | \(try other.render()))"
        }
    }

    /// Negates this predicate using RedisSearch logical `NOT` (`-`).
    ///
    /// Example:
    /// ```swift
    /// let notActive = (\.$isActive == true).not()
    /// // => "(-@isActive:{true})"
    /// ```
    ///
    /// - Returns: A new predicate representing the negation of this predicate.
    public func not() -> Predicate<Model> {
        Predicate {
            "(-\(try self.render()))"
        }
    }
}
