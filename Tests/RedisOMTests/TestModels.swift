import Foundation

@testable import RedisOM

// MARK: Test Models
@Model
struct User: JsonModel {
    @Id var id: String?
    @Index(type: .text) var name: String
    @Index var email: String
    var aliases: [String]?
    @Index(type: .numeric) var age: Int?
    @Index var notes: [Note]?
    @Index var address: [Address]?
    @Index(type: .numeric) var createdAt: Date?

    static let keyPrefix: String = "user"
}

@Model
struct Author: JsonModel {
    @Id var id: String?
    @Index var name: String
    @Index var email: String
    var aliases: [String]?
    var age: Int?
    var notes: [String: Note]
    @Index var createdAt: Date?

    static let keyPrefix: String = "author"
}

@Model
struct Note: JsonModel {
    @Id var id: String?
    @Index(type: .text) var description: String
    var createdAt: Date?

    static let keyPrefix: String = "note"
}

@Model
struct Node: JsonModel {
    @Id var id: String?
    var term: String
    var type: String
    var edges: [Edge]

    static let keyPrefix: String = "misc"
}

@Model
struct Edge: JsonModel {
    @Id var id: String?
    var from: String
    var to: String

    static let keyPrefix: String = "misc"
}

@Model
struct Address: JsonModel {
    @Id var id: String?
    var addressLine1: String
    var addressLine2: String? = nil
    @Index var city: String
    var state: String
    var country: String
    @Index var postalCode: String
    @Index var note: Note? = nil

    static let keyPrefix: String = "address"
}

@Model
struct Person: JsonModel {
    @Id var id: String?
    @Index var name: String
    @Index var email: String
    @Index var address: Address
    var aliases: [String]?
    var age: Int?
    var notes: [Note]?
    @Index(type: .numeric) var createdAt: Date?

    static let keyPrefix: String = "person"
}

@Model
struct Bike: JsonModel {
    @Id var id: String?
    @Index var model: String
    @Index var brand: String
    @Index(type: .numeric) var price: Int
    @Index var type: String
    @Index var specs: Spec
    @Index(type: .text) var description: String?
    var addons: [String]?
    @Index var helmetIncluded: Bool
    var createdAt: Date?

    static let keyPrefix: String = "bike"
}

@Model
struct Spec: JsonModel {
    var id: String?
    @Index var material: String
    @Index(type: .numeric) var weight: Int

    static let keyPrefix: String = "spec"
}

@Model
struct Item: JsonModel {
    @Id var id: String?
    @Index(type: .numeric) var price: Double
    @Index var name: String

    static let keyPrefix: String = "item"
}

@Model
struct Order: JsonModel {
    @Id var id: String?
    @Index var items: [Item]
    var createdOn: Date

    static let keyPrefix: String = "order"
}

@Model
struct Parent: JsonModel {
    @Id var id: String?
    @Index var name: String
    @Index var child: Child

    static let keyPrefix: String = "parent"
}

@Model
struct Child: JsonModel {
    @Id var id: String?
    @Index var name: String
    @Index var pet: Pet

    static let keyPrefix: String = "child"
}

@Model
struct Pet: JsonModel {
    @Id var id: String?
    @Index var species: String
    @Index var name: String

    static let keyPrefix: String = "pet"
}
