import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import RedisOMMacros

final class RedisOMMacrosTests: XCTestCase {

    func testSchemaExpansionSingleTextIndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                var age: Int
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    var age: Int

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text)
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
                @Index var age: Int
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
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
                @Index var email: String
                @Index var age: Int
                @Index var notes: [String]
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int
                    @Index var notes: [String]

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
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
                @Index var email: String
                @Index var age: Int
                @Index var scores: [Double]
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int
                    @Index var scores: [Double]

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
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
                @Index var email: String
                @Index var age: Int
                @Index var scores: [Float]
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int
                    @Index var scores: [Float]

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
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
                @Index var age: Int
                @Index var preferences: [String: Int]
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int
                    @Index var preferences: [String: Int]

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "preferences", type: "[String: Int]", indexType: .text)
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
                @Index var age: Int
                @Index var location: Coordinate
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int
                    @Index var location: Coordinate

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
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

    func testSchemaExpansionDateNumericndex() {
        assertMacroExpansion(
            """
            @ModelSchema
            struct User {
                @AutoID var id: String?
                @Index var email: String
                @Index var age: Int
                @Index var birthdate: Date
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int
                    @Index var birthdate: Date

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "birthdate", type: "Date", indexType: .numeric)
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
                @Index var age: Int
                @Index var notes: [Note]
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
                    @Index var age: Int
                    @Index var notes: [Note]

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
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

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text)
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
                @Index var age: Int
                @Index var notes: [String: Note]
            }

            @ModelSchema
            struct Note: JsonModel {
                @AutoID var id: String?
                @Index var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int
                    @Index var notes: [String: Note]

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
                        Field(name: "age", type: "Int", indexType: .numeric)
                    ]
                    + (((Note.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "notes.\\(f.name)", type: f.type, indexType: f.indexType)
                        } ?? [
                        Field(name: "notes", type: "[String: Note]", indexType: .text)
                        ])
                }
                struct Note: JsonModel {
                    @AutoID var id: String?
                    @Index var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
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
                @Index var material: String
                @Index var weight: Int
            }
            """,
            expandedSource: """
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

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "model", type: "String", indexType: .text),
                        Field(name: "brand", type: "String", indexType: .text),
                        Field(name: "price", type: "Int", indexType: .numeric),
                        Field(name: "type", type: "String", indexType: .text),
                        Field(name: "description", type: "String", indexType: .text),
                        Field(name: "helmetIncluded", type: "Bool", indexType: .tag)
                    ]
                    + (((Spec.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "specs.\\(f.name)", type: f.type, indexType: f.indexType)
                        } ?? [] )
                }
                struct Spec: JsonModel {
                    @Index var material: String
                    @Index var weight: Int

                    public static let schema: [Field] = [
                        Field(name: "material", type: "String", indexType: .text),
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
                @Index var weight: Int

                static let keyPrefix: String = "spec"
            }
            """,
            expandedSource: """
                struct Bike: JsonModel {
                    @AutoID var id: String?
                    @Index var specs: Spec

                    static let keyPrefix: String = "bike"

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text)
                    ]
                    + (((Spec.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "specs.\\(f.name)", type: f.type, indexType: f.indexType)
                        } ?? [] )
                }
                struct Spec: JsonModel {
                    @Index var material: String
                    @Index var weight: Int

                    static let keyPrefix: String = "spec"

                    public static let schema: [Field] = [
                        Field(name: "material", type: "String", indexType: .text),
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
                @Index var age: Int
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

            @ModelSchema
            struct Note: JsonModel {
                @AutoID var id: String?
                @Index var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User {
                    @AutoID var id: String?
                    @Index var email: String
                    @Index var age: Int
                    @Index var notes: [String: Note]
                    @Index var address: Address

                    static let keyPrefix: String = "user"

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
                        Field(name: "age", type: "Int", indexType: .numeric)
                    ]
                    + (((Note.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "notes.\\(f.name)", type: f.type, indexType: f.indexType)
                        } ?? [
                        Field(name: "notes", type: "[String: Note]", indexType: .text)
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

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "city", type: "String", indexType: .text),
                        Field(name: "postalCode", type: "String", indexType: .text)
                    ]
                }
                struct Note: JsonModel {
                    @AutoID var id: String?
                    @Index var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
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
                @Index var age: Int
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
                    @Index var age: Int
                    @Index var notes: [String: Note]
                    @Index var address: Address

                    static let keyPrefix: String = "user"

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
                        Field(name: "age", type: "Int", indexType: .numeric)
                    ]
                    + (((Note.self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "notes.\\(f.name)", type: f.type, indexType: f.indexType)
                        } ?? [
                        Field(name: "notes", type: "[String: Note]", indexType: .text)
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

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "city", type: "String", indexType: .text),
                        Field(name: "postalCode", type: "String", indexType: .text)
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
