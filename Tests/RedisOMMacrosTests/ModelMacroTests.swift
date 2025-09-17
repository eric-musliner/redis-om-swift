import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import RedisOMMacros

final class ModelMacroTests: XCTestCase {

    func testSchemaExpansionSingleTextIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                var age: Int

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
                    @Index var email: String
                    var age: Int

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self.age = age
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self.age = ageDecoded
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "email", type: "String", indexType: .tag)
                    ]
                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionNumericIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int

                    static let keyPrefix: String = "user"

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionArrayofStringIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index(type: .tag) var email: String
                @Index(type: .numeric) var age: Int
                @Index(type: .text) var notes: [String]

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .text)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case notes
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let notesDecoded = try c.decode([String].self, forKey: .notes)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._notes = Index(wrappedValue: notesDecoded, type: .text)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(notes, forKey: .notes)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionVectorDoubleIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
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
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._scores = Index(wrappedValue: scores, type: .vector)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case scores
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let scoresDecoded = try c.decode([Double].self, forKey: .scores)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._scores = Index(wrappedValue: scoresDecoded, type: .vector)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(scores, forKey: .scores)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionVectorFloatIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index(type: .tag) var email: String
                @Index(type: .numeric) var age: Int
                @Index(type: .vector) var scores: [Float]

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._scores = Index(wrappedValue: scores, type: .vector)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case scores
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let scoresDecoded = try c.decode([Float].self, forKey: .scores)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._scores = Index(wrappedValue: scoresDecoded, type: .vector)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(scores, forKey: .scores)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionDictOfStringIntIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var preferences: [String: Int]

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._preferences = Index(wrappedValue: preferences, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case preferences
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let preferencesDecoded = try c.decode([String: Int].self, forKey: .preferences)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._preferences = Index(wrappedValue: preferencesDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(preferences, forKey: .preferences)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionGeoIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index(type: .geo) var location: Coordinate

                static let keyPrefix: String = "user"

            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._location = Index(wrappedValue: location, type: .geo)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case location
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let locationDecoded = try c.decode(Coordinate.self, forKey: .location)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._location = Index(wrappedValue: locationDecoded, type: .geo)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(location, forKey: .location)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionDateNumericIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var birthdate: Date

                static let keyPrefix: String = "user"

            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._birthdate = Index(wrappedValue: birthdate, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case birthdate
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let birthdateDecoded = try c.decode(Date.self, forKey: .birthdate)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._birthdate = Index(wrappedValue: birthdateDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(birthdate, forKey: .birthdate)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionArrayNestedModelIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var notes: [Note]

                static let keyPrefix: String = "user"
            }

            @Model
            struct Note: JsonModel {
                @Id var id: String?
                var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case notes
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let notesDecoded = try c.decode([Note].self, forKey: .notes)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._notes = Index(wrappedValue: notesDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(notes, forKey: .notes)
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
                struct Note: JsonModel {
                    @Id var id: String?
                    var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public init(
                        id: String? = nil,
                        description: String,
                        createdAt: Date? = nil
                    ) {
                        self._id = Id(wrappedValue: id)
                        self.description = description
                        self.createdAt = createdAt
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case description
                        case createdAt
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let descriptionDecoded = try c.decode(String.self, forKey: .description)
                        let createdAtDecoded = try c.decodeIfPresent(Date.self, forKey: .createdAt)

                        self._id = Id(wrappedValue: idDecoded)
                        self.description = descriptionDecoded
                        self.createdAt = createdAtDecoded
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(description, forKey: .description)
                        try c.encodeIfPresent(createdAt, forKey: .createdAt)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionDictNestedModelIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var notes: [String: Note]

                static let keyPrefix: String = "user"
            }

            @Model
            struct Note: JsonModel {
                @Id var id: String?
                @Index(type: .text) var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case notes
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let notesDecoded = try c.decode([String: Note].self, forKey: .notes)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._notes = Index(wrappedValue: notesDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(notes, forKey: .notes)
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
                    @Id var id: String?
                    @Index(type: .text) var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public init(
                        id: String? = nil,
                        description: String,
                        createdAt: Date? = nil
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._description = Index(wrappedValue: description, type: .text)
                        self.createdAt = createdAt
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case description
                        case createdAt
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let descriptionDecoded = try c.decode(String.self, forKey: .description)
                        let createdAtDecoded = try c.decodeIfPresent(Date.self, forKey: .createdAt)

                        self._id = Id(wrappedValue: idDecoded)
                        self._description = Index(wrappedValue: descriptionDecoded, type: .text)
                        self.createdAt = createdAtDecoded
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(description, forKey: .description)
                        try c.encodeIfPresent(createdAt, forKey: .createdAt)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionNested() {
        assertMacroExpansion(
            """
            @Model
            struct Bike: JsonModel {
                @Id var id: String?
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

            @Model
            struct Spec: JsonModel {
                @Index var material: String
                @Index(type: .numeric) var weight: Int

                static let keyPrefix: String = "spec"
            }
            """,
            expandedSource: """
                struct Bike: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
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

                    enum CodingKeys: String, CodingKey {
                        case id
                        case model
                        case brand
                        case price
                        case type
                        case specs
                        case description
                        case addons
                        case helmetIncluded
                        case createdAt
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let modelDecoded = try c.decode(String.self, forKey: .model)
                        let brandDecoded = try c.decode(String.self, forKey: .brand)
                        let priceDecoded = try c.decode(Int.self, forKey: .price)
                        let typeDecoded = try c.decode(String.self, forKey: .type)
                        let specsDecoded = try c.decode(Spec.self, forKey: .specs)
                        let descriptionDecoded = try c.decodeIfPresent(String.self, forKey: .description)
                        let addonsDecoded = try c.decodeIfPresent([String].self, forKey: .addons)
                        let helmetIncludedDecoded = try c.decode(Bool.self, forKey: .helmetIncluded)
                        let createdAtDecoded = try c.decodeIfPresent(Date.self, forKey: .createdAt)

                        self._id = Id(wrappedValue: idDecoded)
                        self._model = Index(wrappedValue: modelDecoded, type: .tag)
                        self._brand = Index(wrappedValue: brandDecoded, type: .tag)
                        self._price = Index(wrappedValue: priceDecoded, type: .numeric)
                        self._type = Index(wrappedValue: typeDecoded, type: .tag)
                        self._specs = Index(wrappedValue: specsDecoded, type: .tag)
                        self._description = Index(wrappedValue: descriptionDecoded, type: .tag)
                        self.addons = addonsDecoded
                        self._helmetIncluded = Index(wrappedValue: helmetIncludedDecoded, type: .tag)
                        self.createdAt = createdAtDecoded
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(model, forKey: .model)
                        try c.encode(brand, forKey: .brand)
                        try c.encode(price, forKey: .price)
                        try c.encode(type, forKey: .type)
                        try c.encode(specs, forKey: .specs)
                        try c.encodeIfPresent(description, forKey: .description)
                        try c.encodeIfPresent(addons, forKey: .addons)
                        try c.encode(helmetIncluded, forKey: .helmetIncluded)
                        try c.encodeIfPresent(createdAt, forKey: .createdAt)
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

                    enum CodingKeys: String, CodingKey {
                        case material
                        case weight
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let materialDecoded = try c.decode(String.self, forKey: .material)
                        let weightDecoded = try c.decode(Int.self, forKey: .weight)

                        self._material = Index(wrappedValue: materialDecoded, type: .tag)
                        self._weight = Index(wrappedValue: weightDecoded, type: .numeric)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encode(material, forKey: .material)
                        try c.encode(weight, forKey: .weight)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionNestedModel() {
        assertMacroExpansion(
            """
            @Model
            struct Bike: JsonModel {
                @Id var id: String?
                @Index var specs: Spec

                static let keyPrefix: String = "bike"
            }

            @Model
            struct Spec: JsonModel {
                @Index var material: String
                @Index(type: .numeric) var weight: Int

                static let keyPrefix: String = "spec"
            }
            """,
            expandedSource: """
                struct Bike: JsonModel {
                    @Id var id: String?
                    @Index var specs: Spec

                    static let keyPrefix: String = "bike"

                    public init(
                        id: String? = nil,
                        specs: Spec
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._specs = Index(wrappedValue: specs, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case specs
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let specsDecoded = try c.decode(Spec.self, forKey: .specs)

                        self._id = Id(wrappedValue: idDecoded)
                        self._specs = Index(wrappedValue: specsDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(specs, forKey: .specs)
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

                    enum CodingKeys: String, CodingKey {
                        case material
                        case weight
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let materialDecoded = try c.decode(String.self, forKey: .material)
                        let weightDecoded = try c.decode(Int.self, forKey: .weight)

                        self._material = Index(wrappedValue: materialDecoded, type: .tag)
                        self._weight = Index(wrappedValue: weightDecoded, type: .numeric)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encode(material, forKey: .material)
                        try c.encode(weight, forKey: .weight)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionDeepNestedModelIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index(type: .text) var notes: [String: Note]
                @Index var address: Address

                static let keyPrefix: String = "user"
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
                var note: Note? = nil

                static let keyPrefix: String = "address"
            }

            @Model
            struct Note: JsonModel {
                @Id var id: String?
                @Index(type: .text) var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .text)
                        self._address = Index(wrappedValue: address, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case notes
                        case address
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let notesDecoded = try c.decode([String: Note].self, forKey: .notes)
                        let addressDecoded = try c.decode(Address.self, forKey: .address)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._notes = Index(wrappedValue: notesDecoded, type: .text)
                        self._address = Index(wrappedValue: addressDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(notes, forKey: .notes)
                        try c.encode(address, forKey: .address)
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
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self.addressLine1 = addressLine1
                        self.addressLine2 = addressLine2
                        self._city = Index(wrappedValue: city, type: .tag)
                        self.state = state
                        self.country = country
                        self._postalCode = Index(wrappedValue: postalCode, type: .tag)
                        self.note = note
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case addressLine1
                        case addressLine2
                        case city
                        case state
                        case country
                        case postalCode
                        case note
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let addressLine1Decoded = try c.decode(String.self, forKey: .addressLine1)
                        let addressLine2Decoded = try c.decode(String? .self, forKey: .addressLine2)
                        let cityDecoded = try c.decode(String.self, forKey: .city)
                        let stateDecoded = try c.decode(String.self, forKey: .state)
                        let countryDecoded = try c.decode(String.self, forKey: .country)
                        let postalCodeDecoded = try c.decode(String.self, forKey: .postalCode)
                        let noteDecoded = try c.decode(Note? .self, forKey: .note)

                        self._id = Id(wrappedValue: idDecoded)
                        self.addressLine1 = addressLine1Decoded
                        self.addressLine2 = addressLine2Decoded
                        self._city = Index(wrappedValue: cityDecoded, type: .tag)
                        self.state = stateDecoded
                        self.country = countryDecoded
                        self._postalCode = Index(wrappedValue: postalCodeDecoded, type: .tag)
                        self.note = noteDecoded
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(addressLine1, forKey: .addressLine1)
                        try c.encode(addressLine2, forKey: .addressLine2)
                        try c.encode(city, forKey: .city)
                        try c.encode(state, forKey: .state)
                        try c.encode(country, forKey: .country)
                        try c.encode(postalCode, forKey: .postalCode)
                        try c.encode(note, forKey: .note)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "city", type: "String", indexType: .tag),
                        Field(name: "postalCode", type: "String", indexType: .tag)
                    ]
                }
                struct Note: JsonModel {
                    @Id var id: String?
                    @Index(type: .text) var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public init(
                        id: String? = nil,
                        description: String,
                        createdAt: Date? = nil
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._description = Index(wrappedValue: description, type: .text)
                        self.createdAt = createdAt
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case description
                        case createdAt
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let descriptionDecoded = try c.decode(String.self, forKey: .description)
                        let createdAtDecoded = try c.decodeIfPresent(Date.self, forKey: .createdAt)

                        self._id = Id(wrappedValue: idDecoded)
                        self._description = Index(wrappedValue: descriptionDecoded, type: .text)
                        self.createdAt = createdAtDecoded
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(description, forKey: .description)
                        try c.encodeIfPresent(createdAt, forKey: .createdAt)
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
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionDeepNestedModelMissingSchemaAttrIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                @Index var notes: [String: Note]
                @Index var address: Address

                static let keyPrefix: String = "user"
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
                var note: Note? = nil

                static let keyPrefix: String = "address"
            }

            struct Note: JsonModel {
                @Id var id: String?
                var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self._notes = Index(wrappedValue: notes, type: .tag)
                        self._address = Index(wrappedValue: address, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case email
                        case age
                        case notes
                        case address
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let ageDecoded = try c.decode(Int.self, forKey: .age)
                        let notesDecoded = try c.decode([String: Note].self, forKey: .notes)
                        let addressDecoded = try c.decode(Address.self, forKey: .address)

                        self._id = Id(wrappedValue: idDecoded)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._age = Index(wrappedValue: ageDecoded, type: .numeric)
                        self._notes = Index(wrappedValue: notesDecoded, type: .tag)
                        self._address = Index(wrappedValue: addressDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(notes, forKey: .notes)
                        try c.encode(address, forKey: .address)
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
                    @Id var id: String?
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
                        self._id = Id(wrappedValue: id)
                        self.addressLine1 = addressLine1
                        self.addressLine2 = addressLine2
                        self._city = Index(wrappedValue: city, type: .tag)
                        self.state = state
                        self.country = country
                        self._postalCode = Index(wrappedValue: postalCode, type: .tag)
                        self.note = note
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case addressLine1
                        case addressLine2
                        case city
                        case state
                        case country
                        case postalCode
                        case note
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let addressLine1Decoded = try c.decode(String.self, forKey: .addressLine1)
                        let addressLine2Decoded = try c.decode(String? .self, forKey: .addressLine2)
                        let cityDecoded = try c.decode(String.self, forKey: .city)
                        let stateDecoded = try c.decode(String.self, forKey: .state)
                        let countryDecoded = try c.decode(String.self, forKey: .country)
                        let postalCodeDecoded = try c.decode(String.self, forKey: .postalCode)
                        let noteDecoded = try c.decode(Note? .self, forKey: .note)

                        self._id = Id(wrappedValue: idDecoded)
                        self.addressLine1 = addressLine1Decoded
                        self.addressLine2 = addressLine2Decoded
                        self._city = Index(wrappedValue: cityDecoded, type: .tag)
                        self.state = stateDecoded
                        self.country = countryDecoded
                        self._postalCode = Index(wrappedValue: postalCodeDecoded, type: .tag)
                        self.note = noteDecoded
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(addressLine1, forKey: .addressLine1)
                        try c.encode(addressLine2, forKey: .addressLine2)
                        try c.encode(city, forKey: .city)
                        try c.encode(state, forKey: .state)
                        try c.encode(country, forKey: .country)
                        try c.encode(postalCode, forKey: .postalCode)
                        try c.encode(note, forKey: .note)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", type: "String", indexType: .tag),
                        Field(name: "city", type: "String", indexType: .tag),
                        Field(name: "postalCode", type: "String", indexType: .tag)
                    ]
                }

                struct Note: JsonModel {
                    @Id var id: String?
                    var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"
                }

                extension User: _SchemaProvider {
                }

                extension Address: _SchemaProvider {
                }
                """,
            macros: ["Model": ModelMacro.self]
        )
    }

}
