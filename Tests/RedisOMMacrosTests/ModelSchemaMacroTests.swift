import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import RedisOMMacros

final class ModelSchemaMacroTests: XCTestCase {

    func testSchemaExpansionSingleTextIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                var age: Int

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    var age: Int

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self.age = age
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag)
                    ]
                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionNumericIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric)
                    ]
                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionArrayofStringIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index(type: .tag) var email: String
                @Index(type: .numeric) var age: Int
                @Index(type: .text) var notes: [String]

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index(type: .tag) var email: String
                    @Index(type: .numeric) var age: Int
                    @Index(type: .text) var notes: [String]

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        notes: [String]
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .text)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "notes", type: "[String]", indexType: .text)
                    ]
                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionVectorDoubleIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index(type: .tag)
                var email: String
                @Index(type: .numeric)
                var age: Int
                @Index(type: .vector)
                var scores: [Double]

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index(type: .tag)
                    var email: String
                    @Index(type: .numeric)
                    var age: Int
                    @Index(type: .vector)
                    var scores: [Double]

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        scores: [Double]
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._scores = Index(wrappedValue: scores, type: .vector)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "scores", type: "[Double]", indexType: .vector)
                    ]
                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionVectorFloatIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index(type: .tag) var email: String
                @Index(type: .numeric) var age: Int
                @Index(type: .vector) var scores: [Float]

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index(type: .tag) var email: String
                    @Index(type: .numeric) var age: Int
                    @Index(type: .vector) var scores: [Float]

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        scores: [Float]
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._scores = Index(wrappedValue: scores, type: .vector)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "scores", type: "[Float]", indexType: .vector)
                    ]
                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionDictOfStringIntIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var preferences: [String: Int]

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int
                    @Index var preferences: [String: Int]

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        preferences: [String: Int]
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._preferences = Index(wrappedValue: preferences, type: .tag)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "preferences", type: "[String: Int]", indexType: .tag)
                    ]
                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionGeoIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index(type: .geo) var location: Coordinate

                static let keyPrefix: String = "user"

            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int
                    @Index(type: .geo) var location: Coordinate

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        location: Coordinate
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._location = Index(wrappedValue: location, type: .geo)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "location", type: "Coordinate", indexType: .geo)
                    ]

                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionDateNumericIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var birthdate: Date

                static let keyPrefix: String = "user"

            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int
                    @Index var birthdate: Date

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        birthdate: Date
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._birthdate = Index(wrappedValue: birthdate, type: .tag)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "birthdate", type: "Date", indexType: .tag)
                    ]

                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionArrayNestedModelIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var notes: [Note]

                static let keyPrefix: String = "user"
            }

            @ModelSchema
            struct Note {
                @AutoID var id: String?
                var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int
                    @Index var notes: [Note]

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        notes: [Note]
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .tag)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric)
                    ]
                    + Note.schema.map { f in
                        Field(name: "notes.\\(f.name)", type: f.type, indexType: f.indexType)
                    }
                }
                struct Note {
                    @AutoID var id: String?
                    var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public init(
                        id: String? = nil,
                        description: String,
                        createdAt: Date? = nil
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self.description = description
                        self.createdAt = createdAt
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag)
                    ]
                }

                extension User: _SchemaProvider {
                }

                extension Note: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionDictNestedModelIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var notes: [String: Note]

                static let keyPrefix: String = "user"
            }

            @ModelSchema
            struct Note: JsonModel {
                @AutoID var id: String?
                @Index(type: .text) var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int
                    @Index var notes: [String: Note]

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        notes: [String: Note]
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .tag)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric)
                    ]
                    + (((Note.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "notes.\\(f.name)", type: f.type, indexType: f.indexType)
                    } ?? [
                        Field(name: "notes", type: "[String: Note]", indexType: .tag)
                    ])
                }
                struct Note: JsonModel {
                    @AutoID var id: String?
                    @Index(type: .text) var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public init(
                        id: String? = nil,
                        description: String,
                        createdAt: Date? = nil
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._description = Index(wrappedValue: description, type: .text)
                        self.createdAt = createdAt
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "description", type: "String", indexType: .text)
                    ]
                }

                extension User: _SchemaProvider {
                }

                extension Note: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionNested() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct Bike: JsonModel {
                @AutoID var id: String?
                @Index var model: String
                @Index var brand: String
                @Index(type: .numeric) var price: Int
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
                @Index var material: String
                @Index(type: .numeric) var weight: Int

                static let keyPrefix: String = "spec"
            }
            """,
            expandedSource: """
                struct Bike: JsonModel {
                    @AutoID var id: String?
                    @Index var model: String
                    @Index var brand: String
                    @Index(type: .numeric) var price: Int
                    @Index var type: String
                    @Index var specs: Spec
                    @Index var description: String?
                    var addons: [String]?
                    @Index var helmetIncluded: Bool
                    var createdAt: Date?

                    static let keyPrefix: String = "bike"

                    public init(
                        id: String? = nil,
                        model: String,
                        brand: String,
                        price: Int,
                        type: String,
                        specs: Spec,
                        description: String? = nil,
                        addons: [String]? = nil,
                        helmetIncluded: Bool,
                        createdAt: Date? = nil
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._model = Index(wrappedValue: model, type: .tag)
                        self._brand = Index(wrappedValue: brand, type: .tag)
                        self._price = Index(wrappedValue: price, type: .numeric)
                        self._type = Index(wrappedValue: type, type: .tag)
                        self._specs = Index(wrappedValue: specs, type: .tag)
                        self._description = Index(wrappedValue: description, type: .tag)
                        self.addons = addons
                        self._helmetIncluded = Index(wrappedValue: helmetIncluded, type: .tag)
                        self.createdAt = createdAt
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "model", type: "String", indexType: .tag),
                        Field(name: "brand", type: "String", indexType: .tag),
                        Field(name: "price", type: "Int", indexType: .numeric),
                        Field(name: "type", type: "String", indexType: .tag),
                        Field(name: "description", type: "String", indexType: .tag),
                        Field(name: "helmetIncluded", type: "Bool", indexType: .tag)
                    ]
                    + (((Spec.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "specs.\\(f.name)", type: f.type, indexType: f.indexType)
                    } ?? [] )
                }
                struct Spec: JsonModel {
                    @Index var material: String
                    @Index(type: .numeric) var weight: Int

                    static let keyPrefix: String = "spec"

                    public init(
                        material: String,
                        weight: Int
                    ) {
                        self._material = Index(wrappedValue: material, type: .tag)
                        self._weight = Index(wrappedValue: weight, type: .numeric)
                    }

                    public static let schema: [Field] = [
                        Field(name: "material", type: "String", indexType: .tag),
                        Field(name: "weight", type: "Int", indexType: .numeric)
                    ]
                }

                extension Bike: _SchemaProvider {
                }

                extension Spec: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionNestedModel() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct Bike: JsonModel {
                @AutoID var id: String?
                @Index var specs: Spec

                static let keyPrefix: String = "bike"
            }

            @ModelSchema
            struct Spec: JsonModel {
                @Index var material: String
                @Index(type: .numeric) var weight: Int

                static let keyPrefix: String = "spec"
            }
            """,
            expandedSource: """
                struct Bike: JsonModel {
                    @AutoID var id: String?
                    @Index var specs: Spec

                    static let keyPrefix: String = "bike"

                    public init(
                        id: String? = nil,
                        specs: Spec
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._specs = Index(wrappedValue: specs, type: .tag)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag)
                    ]
                    + (((Spec.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "specs.\\(f.name)", type: f.type, indexType: f.indexType)
                    } ?? [] )
                }
                struct Spec: JsonModel {
                    @Index var material: String
                    @Index(type: .numeric) var weight: Int

                    static let keyPrefix: String = "spec"

                    public init(
                        material: String,
                        weight: Int
                    ) {
                        self._material = Index(wrappedValue: material, type: .tag)
                        self._weight = Index(wrappedValue: weight, type: .numeric)
                    }

                    public static let schema: [Field] = [
                        Field(name: "material", type: "String", indexType: .tag),
                        Field(name: "weight", type: "Int", indexType: .numeric)
                    ]
                }

                extension Bike: _SchemaProvider {
                }

                extension Spec: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionDeepNestedModelIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index(type: .text) var notes: [String: Note]
                @Index var address: Address

                static let keyPrefix: String = "user"
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
                var note: Note? = nil

                static let keyPrefix: String = "address"
            }

            @ModelSchema
            struct Note: JsonModel {
                @AutoID var id: String?
                @Index(type: .text) var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int
                    @Index(type: .text) var notes: [String: Note]
                    @Index var address: Address

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        notes: [String: Note],
                        address: Address
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .text)
                        self._address = Index(wrappedValue: address, type: .tag)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric)
                    ]
                    + (((Note.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "notes.\\(f.name)", type: f.type, indexType: f.indexType)
                    } ?? [
                        Field(name: "notes", type: "[String: Note]", indexType: .tag)
                    ])
                    + (((Address.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "address.\\(f.name)", type: f.type, indexType: f.indexType)
                    } ?? [] )
                }
                struct Address: JsonModel {
                    @AutoID var id: String?
                    var addressLine1: String
                    var addressLine2: String? = nil
                    @Index var city: String
                    var state: String
                    var country: String
                    @Index var postalCode: String
                    var note: Note? = nil

                    static let keyPrefix: String = "address"

                    public init(
                        id: String? = nil,
                        addressLine1: String,
                        addressLine2: String? = nil,
                        city: String,
                        state: String,
                        country: String,
                        postalCode: String,
                        note: Note? = nil
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self.addressLine1 = addressLine1
                        self.addressLine2 = addressLine2
                        self._city = Index(wrappedValue: city, type: .tag)
                        self.state = state
                        self.country = country
                        self._postalCode = Index(wrappedValue: postalCode, type: .tag)
                        self.note = note
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "city", type: "String", indexType: .tag),
                        Field(name: "postalCode", type: "String", indexType: .tag)
                    ]
                }
                struct Note: JsonModel {
                    @AutoID var id: String?
                    @Index(type: .text) var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public init(
                        id: String? = nil,
                        description: String,
                        createdAt: Date? = nil
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._description = Index(wrappedValue: description, type: .text)
                        self.createdAt = createdAt
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "description", type: "String", indexType: .text)
                    ]
                }

                extension User: _SchemaProvider {
                }

                extension Address: _SchemaProvider {
                }

                extension Note: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionDeepNestedModelMissingSchemaAttrIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var notes: [String: Note]
                @Index var address: Address

                static let keyPrefix: String = "user"
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
                var note: Note? = nil

                static let keyPrefix: String = "address"
            }

            struct Note: JsonModel {
                @AutoID var id: String?
                var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int
                    @Index var notes: [String: Note]
                    @Index var address: Address

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        notes: [String: Note],
                        address: Address
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .tag)
                        self._address = Index(wrappedValue: address, type: .tag)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag),
                        Field(name: "age", type: "Int", indexType: .numeric)
                    ]
                    + (((Note.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "notes.\\(f.name)", type: f.type, indexType: f.indexType)
                    } ?? [
                        Field(name: "notes", type: "[String: Note]", indexType: .tag)
                    ])
                    + (((Address.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "address.\\(f.name)", type: f.type, indexType: f.indexType)
                    } ?? [] )
                }
                struct Address: JsonModel {
                    @AutoID var id: String?
                    var addressLine1: String
                    var addressLine2: String? = nil
                    @Index var city: String
                    var state: String
                    var country: String
                    @Index var postalCode: String
                    var note: Note? = nil

                    static let keyPrefix: String = "address"

                    public init(
                        id: String? = nil,
                        addressLine1: String,
                        addressLine2: String? = nil,
                        city: String,
                        state: String,
                        country: String,
                        postalCode: String,
                        note: Note? = nil
                    ) {
                        self._id = AutoID(wrappedValue: id)
                        self.addressLine1 = addressLine1
                        self.addressLine2 = addressLine2
                        self._city = Index(wrappedValue: city, type: .tag)
                        self.state = state
                        self.country = country
                        self._postalCode = Index(wrappedValue: postalCode, type: .tag)
                        self.note = note
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "city", type: "String", indexType: .tag),
                        Field(name: "postalCode", type: "String", indexType: .tag)
                    ]
                }

                struct Note: JsonModel {
                    @AutoID var id: String?
                    var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"
                }

                extension User: _SchemaProvider {
                }

                extension Address: _SchemaProvider {
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

}
