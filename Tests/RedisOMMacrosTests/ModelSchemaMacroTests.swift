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
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

    func testSchemaExpansionArrayofDoubleIndex() {
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
                        Field(name: "scores", type: "[Double]", indexType: .numeric)
                    ]
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
                        Field(name: "preferences", type: "[String: Int]", indexType: .numeric)
                    ]
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
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "notes", type: "[Note]", indexType: .tag)
                    ]
                }

                struct Note {
                    @AutoID var id: String?
                    var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"
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
                    @Index var notes: [String: Note]

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .text),
                        Field(name: "email", type: "String", indexType: .text),
                        Field(name: "age", type: "Int", indexType: .numeric),
                        Field(name: "notes", type: "[String: Note]", indexType: .tag)
                    ]
                }

                struct Note {
                    @AutoID var id: String?
                    var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"
                }
                """,
            macros: ["ModelSchema": ModelSchemaMacro.self]
        )
    }

}
