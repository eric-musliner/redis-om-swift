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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )
                    public static let $notes = FieldRef<[String]>(
                        indexType: .text,
                        aliasPath: ["notes"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric),
                        Field(name: "notes", alias: "notes", jsonPath: "$.notes[*]", indexType: .text)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )
                    public static let $scores = FieldRef<[Double]>(
                        indexType: .vector,
                        aliasPath: ["scores"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric),
                        Field(name: "scores", alias: "scores", jsonPath: "$.scores[*]", indexType: .vector)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )
                    public static let $scores = FieldRef<[Float]>(
                        indexType: .vector,
                        aliasPath: ["scores"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric),
                        Field(name: "scores", alias: "scores", jsonPath: "$.scores[*]", indexType: .vector)
                    ]
                }

                extension User: _SchemaProvider {
                }
                """,
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionUnindexedDictOfStringIntIndex() {
        assertMacroExpansion(
            """
            @Model
            struct User: JsonModel {
                @Id var id: String?
                @Index var email: String
                @Index(type: .numeric) var age: Int
                var preferences: [String: Int]

                static let keyPrefix: String = "user"
            }
            """,
            expandedSource: """
                struct User: JsonModel {
                    @Id var id: String?
                    @Index var email: String
                    @Index(type: .numeric) var age: Int
                    var preferences: [String: Int]

                    static let keyPrefix: String = "user"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        preferences: [String: Int]
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._age = Index(wrappedValue: age, type: .numeric)
                        self.preferences = preferences
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
                        self.preferences = preferencesDecoded
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(email, forKey: .email)
                        try c.encode(age, forKey: .age)
                        try c.encode(preferences, forKey: .preferences)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )
                    public static let $location = FieldRef<Coordinate>(
                        indexType: .geo,
                        aliasPath: ["location"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric),
                        Field(name: "location", alias: "location", jsonPath: "$.location", indexType: .geo)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )
                    public static let $birthdate = FieldRef<Date>(
                        indexType: .tag,
                        aliasPath: ["birthdate"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric),
                        Field(name: "birthdate", alias: "birthdate", jsonPath: "$.birthdate", indexType: .tag)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )
                    public static let $notes = FieldRef<[Note]>(
                        indexType: .tag,
                        aliasPath: ["notes"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric)
                    ]
                    + [
                        Field(name: "notes", alias: "notes", jsonPath: "$.notes[*]", indexType: .tag, nestedSchema: (((Note.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                }
                struct Note: JsonModel {
                    @Id var id: String?
                    var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $model = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["model"]
                    )
                    public static let $brand = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["brand"]
                    )
                    public static let $price = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["price"]
                    )
                    public static let $type = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["type"]
                    )
                    public static let $specs = FieldRef<Spec>(
                        indexType: .tag,
                        aliasPath: ["specs"]
                    )
                    public static let $description = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["description"]
                    )
                    public static let $helmetIncluded = FieldRef<Bool>(
                        indexType: .tag,
                        aliasPath: ["helmetIncluded"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "model", alias: "model", jsonPath: "$.model", indexType: .tag),
                        Field(name: "brand", alias: "brand", jsonPath: "$.brand", indexType: .tag),
                        Field(name: "price", alias: "price", jsonPath: "$.price", indexType: .numeric),
                        Field(name: "type", alias: "type", jsonPath: "$.type", indexType: .tag),
                        Field(name: "description", alias: "description", jsonPath: "$.description", indexType: .tag),
                        Field(name: "helmetIncluded", alias: "helmetIncluded", jsonPath: "$.helmetIncluded", indexType: .tag)
                    ]
                    + [
                        Field(name: "specs", alias: "specs", jsonPath: "$.specs",indexType: .tag, nestedSchema: (((Spec.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                }
                struct Spec: JsonModel {
                    @Index var material: String
                    @Index(type: .numeric) var weight: Int

                    static let keyPrefix: String = "spec"

                    public static let $material = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["material"]
                    )
                    public static let $weight = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["weight"]
                    )

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
                        Field(name: "material", alias: "material", jsonPath: "$.material", indexType: .tag),
                        Field(name: "weight", alias: "weight", jsonPath: "$.weight", indexType: .numeric)
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $specs = FieldRef<Spec>(
                        indexType: .tag,
                        aliasPath: ["specs"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag)
                    ]
                    + [
                        Field(name: "specs", alias: "specs", jsonPath: "$.specs",indexType: .tag, nestedSchema: (((Spec.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                }
                struct Spec: JsonModel {
                    @Index var material: String
                    @Index(type: .numeric) var weight: Int

                    static let keyPrefix: String = "spec"

                    public static let $material = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["material"]
                    )
                    public static let $weight = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["weight"]
                    )

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
                        Field(name: "material", alias: "material", jsonPath: "$.material", indexType: .tag),
                        Field(name: "weight", alias: "weight", jsonPath: "$.weight", indexType: .numeric)
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
                @Index(type: .text) var notes: [Note]
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
                    @Index(type: .text) var notes: [Note]
                    @Index var address: Address

                    static let keyPrefix: String = "user"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )
                    public static let $notes = FieldRef<[Note]>(
                        indexType: .text,
                        aliasPath: ["notes"]
                    )
                    public static let $address = FieldRef<Address>(
                        indexType: .tag,
                        aliasPath: ["address"]
                    )

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        notes: [Note],
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
                        let notesDecoded = try c.decode([Note].self, forKey: .notes)
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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric)
                    ]
                    + [
                        Field(name: "notes", alias: "notes", jsonPath: "$.notes[*]", indexType: .text, nestedSchema: (((Note.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                    + [
                        Field(name: "address", alias: "address", jsonPath: "$.address",indexType: .tag, nestedSchema: (((Address.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $city = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["city"]
                    )
                    public static let $postalCode = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["postalCode"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "city", alias: "city", jsonPath: "$.city", indexType: .tag),
                        Field(name: "postalCode", alias: "postalCode", jsonPath: "$.postalCode", indexType: .tag)
                    ]
                }
                struct Note: JsonModel {
                    @Id var id: String?
                    @Index(type: .text) var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $description = FieldRef<String>(
                        indexType: .text,
                        aliasPath: ["description"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "description", alias: "description", jsonPath: "$.description", indexType: .text)
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
                @Index var notes: [Note]
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
                    @Index var notes: [Note]
                    @Index var address: Address

                    static let keyPrefix: String = "user"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $age = FieldRef<Int>(
                        indexType: .numeric,
                        aliasPath: ["age"]
                    )
                    public static let $notes = FieldRef<[Note]>(
                        indexType: .tag,
                        aliasPath: ["notes"]
                    )
                    public static let $address = FieldRef<Address>(
                        indexType: .tag,
                        aliasPath: ["address"]
                    )

                    public init(
                        id: String? = nil,
                        email: String,
                        age: Int,
                        notes: [Note],
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
                        let notesDecoded = try c.decode([Note].self, forKey: .notes)
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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "age", alias: "age", jsonPath: "$.age", indexType: .numeric)
                    ]
                    + [
                        Field(name: "notes", alias: "notes", jsonPath: "$.notes[*]", indexType: .tag, nestedSchema: (((Note.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                    + [
                        Field(name: "address", alias: "address", jsonPath: "$.address",indexType: .tag, nestedSchema: (((Address.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $city = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["city"]
                    )
                    public static let $postalCode = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["postalCode"]
                    )

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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "city", alias: "city", jsonPath: "$.city", indexType: .tag),
                        Field(name: "postalCode", alias: "postalCode", jsonPath: "$.postalCode", indexType: .tag)
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

    func testSchemaExpansionPersonNestedAddressModel() {
        assertMacroExpansion(
            """
            @Model
            struct Person: JsonModel {
                @Id var id: String?
                @Index var name: String
                @Index var email: String
                @Index var address: Address
                @Index var aliases: [String]?
                var age: Int?
                var notes: [Note]?
                @Index(type: .numeric) var createdAt: Date?

                static let keyPrefix: String = "person"
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

            struct Note: JsonModel {
                @Id var id: String?
                var description: String
                var createdAt: Date?

                static let keyPrefix: String = "note"
            }
            """,
            expandedSource: """
                struct Person: JsonModel {
                    @Id var id: String?
                    @Index var name: String
                    @Index var email: String
                    @Index var address: Address
                    @Index var aliases: [String]?
                    var age: Int?
                    var notes: [Note]?
                    @Index(type: .numeric) var createdAt: Date?

                    static let keyPrefix: String = "person"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $name = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["name"]
                    )
                    public static let $email = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["email"]
                    )
                    public static let $address = FieldRef<Address>(
                        indexType: .tag,
                        aliasPath: ["address"]
                    )
                    public static let $aliases = FieldRef<[String]?>(
                        indexType: .tag,
                        aliasPath: ["aliases"]
                    )
                    public static let $createdAt = FieldRef<Date?>(
                        indexType: .numeric,
                        aliasPath: ["createdAt"]
                    )

                    public init(
                        id: String? = nil,
                        name: String,
                        email: String,
                        address: Address,
                        aliases: [String]? = nil,
                        age: Int? = nil,
                        notes: [Note]? = nil,
                        createdAt: Date? = nil
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._name = Index(wrappedValue: name, type: .tag)
                        self._email = Index(wrappedValue: email, type: .tag)
                        self._address = Index(wrappedValue: address, type: .tag)
                        self._aliases = Index(wrappedValue: aliases, type: .tag)
                        self.age = age
                        self.notes = notes
                        self._createdAt = Index(wrappedValue: createdAt, type: .numeric)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case name
                        case email
                        case address
                        case aliases
                        case age
                        case notes
                        case createdAt
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let nameDecoded = try c.decode(String.self, forKey: .name)
                        let emailDecoded = try c.decode(String.self, forKey: .email)
                        let addressDecoded = try c.decode(Address.self, forKey: .address)
                        let aliasesDecoded = try c.decodeIfPresent([String].self, forKey: .aliases)
                        let ageDecoded = try c.decodeIfPresent(Int.self, forKey: .age)
                        let notesDecoded = try c.decodeIfPresent([Note].self, forKey: .notes)
                        let createdAtDecoded = try c.decodeIfPresent(Date.self, forKey: .createdAt)

                        self._id = Id(wrappedValue: idDecoded)
                        self._name = Index(wrappedValue: nameDecoded, type: .tag)
                        self._email = Index(wrappedValue: emailDecoded, type: .tag)
                        self._address = Index(wrappedValue: addressDecoded, type: .tag)
                        self._aliases = Index(wrappedValue: aliasesDecoded, type: .tag)
                        self.age = ageDecoded
                        self.notes = notesDecoded
                        self._createdAt = Index(wrappedValue: createdAtDecoded, type: .numeric)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(name, forKey: .name)
                        try c.encode(email, forKey: .email)
                        try c.encode(address, forKey: .address)
                        try c.encodeIfPresent(aliases, forKey: .aliases)
                        try c.encodeIfPresent(age, forKey: .age)
                        try c.encodeIfPresent(notes, forKey: .notes)
                        try c.encodeIfPresent(createdAt, forKey: .createdAt)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "name", alias: "name", jsonPath: "$.name", indexType: .tag),
                        Field(name: "email", alias: "email", jsonPath: "$.email", indexType: .tag),
                        Field(name: "aliases", alias: "aliases", jsonPath: "$.aliases[*]", indexType: .tag),
                        Field(name: "createdAt", alias: "createdAt", jsonPath: "$.createdAt", indexType: .numeric)
                    ]
                    + [
                        Field(name: "address", alias: "address", jsonPath: "$.address",indexType: .tag, nestedSchema: (((Address.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                }
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

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $city = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["city"]
                    )
                    public static let $postalCode = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["postalCode"]
                    )
                    public static let $note = FieldRef<Note?>(
                        indexType: .tag,
                        aliasPath: ["note"]
                    )

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
                        self._note = Index(wrappedValue: note, type: .tag)
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
                        self._note = Index(wrappedValue: noteDecoded, type: .tag)
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
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "city", alias: "city", jsonPath: "$.city", indexType: .tag),
                        Field(name: "postalCode", alias: "postalCode", jsonPath: "$.postalCode", indexType: .tag)
                    ]
                    + [
                        Field(name: "note", alias: "note", jsonPath: "$.note",indexType: .tag, nestedSchema: (((Note.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                }

                struct Note: JsonModel {
                    @Id var id: String?
                    var description: String
                    var createdAt: Date?

                    static let keyPrefix: String = "note"
                }

                extension Person: _SchemaProvider {
                }

                extension Address: _SchemaProvider {
                }
                """,
            macros: ["Model": ModelMacro.self]
        )
    }

    func testSchemaExpansionDeepSimpleNesting() {
        assertMacroExpansion(
            """
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
            """,
            expandedSource: """
                struct Parent: JsonModel {
                    @Id var id: String?
                    @Index var name: String
                    @Index var child: Child

                    static let keyPrefix: String = "parent"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $name = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["name"]
                    )
                    public static let $child = FieldRef<Child>(
                        indexType: .tag,
                        aliasPath: ["child"]
                    )

                    public init(
                        id: String? = nil,
                        name: String,
                        child: Child
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._name = Index(wrappedValue: name, type: .tag)
                        self._child = Index(wrappedValue: child, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case name
                        case child
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let nameDecoded = try c.decode(String.self, forKey: .name)
                        let childDecoded = try c.decode(Child.self, forKey: .child)

                        self._id = Id(wrappedValue: idDecoded)
                        self._name = Index(wrappedValue: nameDecoded, type: .tag)
                        self._child = Index(wrappedValue: childDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(name, forKey: .name)
                        try c.encode(child, forKey: .child)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "name", alias: "name", jsonPath: "$.name", indexType: .tag)
                    ]
                    + [
                        Field(name: "child", alias: "child", jsonPath: "$.child",indexType: .tag, nestedSchema: (((Child.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                }
                struct Child: JsonModel {
                    @Id var id: String?
                    @Index var name: String
                    @Index var pet: Pet

                    static let keyPrefix: String = "child"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $name = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["name"]
                    )
                    public static let $pet = FieldRef<Pet>(
                        indexType: .tag,
                        aliasPath: ["pet"]
                    )

                    public init(
                        id: String? = nil,
                        name: String,
                        pet: Pet
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._name = Index(wrappedValue: name, type: .tag)
                        self._pet = Index(wrappedValue: pet, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case name
                        case pet
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let nameDecoded = try c.decode(String.self, forKey: .name)
                        let petDecoded = try c.decode(Pet.self, forKey: .pet)

                        self._id = Id(wrappedValue: idDecoded)
                        self._name = Index(wrappedValue: nameDecoded, type: .tag)
                        self._pet = Index(wrappedValue: petDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(name, forKey: .name)
                        try c.encode(pet, forKey: .pet)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "name", alias: "name", jsonPath: "$.name", indexType: .tag)
                    ]
                    + [
                        Field(name: "pet", alias: "pet", jsonPath: "$.pet",indexType: .tag, nestedSchema: (((Pet.self as Any.Type) as? _SchemaProvider.Type)?.schema))
                    ]
                }
                struct Pet: JsonModel {
                    @Id var id: String?
                    @Index var species: String
                    @Index var name: String

                    static let keyPrefix: String = "pet"

                    public static let $id = FieldRef<String?>(
                        indexType: .tag,
                        aliasPath: ["id"]
                    )
                    public static let $species = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["species"]
                    )
                    public static let $name = FieldRef<String>(
                        indexType: .tag,
                        aliasPath: ["name"]
                    )

                    public init(
                        id: String? = nil,
                        species: String,
                        name: String
                    ) {
                        self._id = Id(wrappedValue: id)
                        self._species = Index(wrappedValue: species, type: .tag)
                        self._name = Index(wrappedValue: name, type: .tag)
                    }

                    enum CodingKeys: String, CodingKey {
                        case id
                        case species
                        case name
                    }

                    public init(from decoder: Decoder) throws {
                        let c = try decoder.container(keyedBy: CodingKeys.self)
                        let idDecoded = try c.decodeIfPresent(String.self, forKey: .id)
                        let speciesDecoded = try c.decode(String.self, forKey: .species)
                        let nameDecoded = try c.decode(String.self, forKey: .name)

                        self._id = Id(wrappedValue: idDecoded)
                        self._species = Index(wrappedValue: speciesDecoded, type: .tag)
                        self._name = Index(wrappedValue: nameDecoded, type: .tag)
                    }

                    public func encode(to encoder: Encoder) throws {
                        var c = encoder.container(keyedBy: CodingKeys.self)
                        try c.encodeIfPresent(id, forKey: .id)
                        try c.encode(species, forKey: .species)
                        try c.encode(name, forKey: .name)
                    }

                    public static let schema: [Field] = [
                        Field(name: "id", alias: "id", jsonPath: "$.id", indexType: .tag),
                        Field(name: "species", alias: "species", jsonPath: "$.species", indexType: .tag),
                        Field(name: "name", alias: "name", jsonPath: "$.name", indexType: .tag)
                    ]
                }

                extension Parent: _SchemaProvider {
                }

                extension Child: _SchemaProvider {
                }

                extension Pet: _SchemaProvider {
                }
                """,
            macros: ["Model": ModelMacro.self]
        )
    }

}
