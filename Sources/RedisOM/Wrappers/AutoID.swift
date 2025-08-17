import Foundation

@propertyWrapper
public struct AutoID: Codable, Sendable {
    public var wrappedValue: String?

    public init(wrappedValue: String? = nil) {
        self.wrappedValue = wrappedValue ?? UUID().uuidString
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try? container.decode(String.self)
        self.wrappedValue = decoded?.isEmpty == false ? decoded! : UUID().uuidString
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
