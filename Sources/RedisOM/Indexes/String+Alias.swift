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
/// "address.city".alias()         // "address__city"
/// "notes[*].description".aliasred() // "notes__description"
/// ```
extension String {
    func alias() -> String {
        // replace disallowed chars (dot, brackets) with underscores
        return
            self
            .replacingOccurrences(of: ".", with: "__")
            .replacingOccurrences(of: "[*]", with: "")
    }
}
