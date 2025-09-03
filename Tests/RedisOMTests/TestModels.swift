import Foundation

@testable import RedisOM

// MARK: Test Models
@ModelSchema
struct User: JsonModel {
    @AutoID var id: String?
    @Index var name: String
    @Index var email: String
    var aliases: [String]?
    var age: Int?
    @Index var notes: [Note]?
    @Index var address: [Address]?
    var createdAt: Date?

    static let keyPrefix: String = "user"
}

@ModelSchema
struct Author: JsonModel {
    @AutoID var id: String?
    @Index var name: String
    @Index var email: String
    var aliases: [String]?
    var age: Int?
    @Index var notes: [String: Note]
    var createdAt: Date?

    static let keyPrefix: String = "author"
}

@ModelSchema
struct Note: JsonModel {
    @AutoID var id: String?
    @Index var description: String
    var createdAt: Date?

    static let keyPrefix: String = "note"
}

@ModelSchema
struct Node: JsonModel {
    @AutoID var id: String?
    var term: String
    var type: String
    var edges: [Edge]

    static let keyPrefix: String = "misc"
}

struct Edge: JsonModel {
    @AutoID var id: String?
    var from: String
    var to: String

    static let keyPrefix: String = "misc"
}

@ModelSchema
struct Address: JsonModel {
    @AutoID var id: String?
    var addressLine1: String
    var addressLine2: String? = nil
    @Index var city: String
    var state: String
    var country: String
    @Index var postalCode: String
    @Index var note: Note? = nil

    static let keyPrefix: String = "address"
}

@ModelSchema
struct Person: JsonModel {
    @AutoID var id: String?
    @Index var name: String
    @Index var email: String
    var aliases: [String]?
    var age: Int?
    var notes: [Note]?
    var createdAt: Date?

    static let keyPrefix: String = "person"
}

@ModelSchema
struct Bike: JsonModel {
    @AutoID var id: String?
    @Index var model: String
    @Index var brand: String
    @Index var price: Int
    @Index var type: String
    @Index var specs: Spec
    @Index var description: String?
    var addons: [String]?
    @Index var helmetIncluded: Bool
    var createdAt: Date?

    static let keyPrefix: String = "bike"
}

@ModelSchema
struct Spec: JsonModel {
    var id: String?
    @Index var material: String
    @Index var weight: Int

    static let keyPrefix: String = "spec"
}

@ModelSchema
struct Item: JsonModel {
    @AutoID var id: String?
    var price: Double
    @Index var name: String

    static let keyPrefix: String = "item"
}

@ModelSchema
struct Order: JsonModel {
    @AutoID var id: String?
    @Index var items: [Item]
    var createdOn: Date

    static let keyPrefix: String = "order"
}
