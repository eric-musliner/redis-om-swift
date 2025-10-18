import Foundation
import RedisOMCore
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that synthesizes a RedisOM schema definition for a model type.
///
/// Apply `@Model` to a `struct` or `class` that defines stored properties
/// annotated with property macros such as ``Index`` or ``Id``. The macro
/// will expand the type with a static `schema` definition describing all fields,
/// their Swift type, and their Redis index configuration. Codable conformance is also attached to allow use
/// of Index property wrapper with no wrappedValue
///
/// The generated schema is used by RedisOM to automatically create indexes
/// and map Redis data back into your Swift model.
///
/// Example:
///
/// ```swift
/// @Model
/// struct User: JsonModel {
///     @Id var id: String
///     @Index var email: String
///     @Index(type: .numeric) var age: Int
///     var notes: [String]
///     var createdAt: Date
///
///     static let keyPrefix: String = "user"
/// }
/// ```
///
/// Expands to:
///
/// ```swift
/// struct User {
///     @Id var id: String
///     @Index var email: String
///     @Index(type: .numeric) var age: Int
///     var notes: [String]
///     var createdAt: Date
///
///     static let keyPrefix: String = "user"
///
///     public static let $id = FieldRef<String?>(
///        indexType: .tag,
///        aliasPath: ["id"]
///     )
///     public static let $email = FieldRef<String>(
///        indexType: .tag,
///        aliasPath: ["email"]
///     )
///     public static let $age = FieldRef<Int>(
///        indexType: .numeric,
///        aliasPath: ["age"]
///     )
///
///     init(
///         id: String,
///         email: String,
///         age: Int,
///         notes: [String],
///         createdAt: Date
///     ) {
///         self.id = id = Id(wrappedValue: id)
///         self._email = Index(wrappedValue: name, type: .tag)
///         self._age = Index(wrappedValue: age, type: .numeric)
///         self.notes = notes
///         self.createdAt = createdAt
///     }
///
///     enum CodingKeys: String, CodingKey {
///         case id, email, age, notes, createdAt
///     }
///
///     init(from decoder: Decoder) throws {
///         let c = try decoder.container(keyedBy: CodingKeys.self)
///         let idDecoded = try c.decode(String.self, forKey: .id)
///         let emailDecoded = try c.decode(String.self, forKey: .email)
///         let ageDecoded = try c.decode(Int.self, forKey: .age)
///         let notesDecoded = try c.decode([String].self, forKey: .notes)
///         let createdAtDecoded = try c.decode(Date.self, forKey: .createdAt)
///
///         self._id = Id(wrappedValue: idDecoded)
///         self._email = Index(wrappedValue: emailDecoded, type: .tag)
///         self.age = ageDecoded
///         self.notes = notesDecoded
///         self.createdAt = createdAtDecoded
///     }
///
///     func encode(to encoder: Encoder) throws {
///         let c = encoder.container(keyedBy: CodingKeys.self)
///         try c.encode(id, forKey: .id)
///         try c.encode(email, forKey: .email)
///         try c.encode(age, forKey: .age)
///         try c.encode(notes, forKey: .notes)
///         try c.encode(createdAt, forKey: .createdAt)
///     }
///
///     public static let schema: [Field] = [
///         Field(name: "id", type: "String", indexType: .tag),
///         Field(name: "email", type: "String", indexType: .tag),
///         Field(name: "age", type: "Int", indexType: .numeric),
///     ]
/// }
///
/// extension User: _SchemaProvider {
/// }
/// ```
///
/// - Note: Only stored properties annotated with ``Index`` or ``Id``
///   are included in the schema. Other properties are ignored.
public struct ModelMacro: MemberMacro, ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try expansion(
            of: node,
            providingMembersOf: decl,
            conformingTo: [],
            in: context
        )
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return []
        }

        var scalarFields: [String] = []
        var nestedSchemas: [String] = []
        var staticFieldRefs: [String] = []

        func makeStaticRefDecl(pathComponent name: String, typeName: String, indexType: String)
            -> String
        {
            return """
                public static let $\((name)) = FieldRef<\(typeName)>(
                    indexType: \(indexType),
                    aliasPath: ["\(name)"]
                )
                """
        }

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.first,
                let identifier = binding.pattern.as(
                    IdentifierPatternSyntax.self
                ),
                let attributes = member.decl.as(VariableDeclSyntax.self)?
                    .attributes
            else { continue }

            let name = identifier.identifier.text

            // Annotated with Index or Id wrapper
            let hasIndexAttr = attributes.contains {
                if let attr = $0.as(AttributeSyntax.self) {
                    let name = attr.attributeName.description
                        .trimmingCharacters(in: .whitespaces)
                    return name == "Index" || name == "Id"
                }
                return false
            }
            var indexType = ".tag"

            guard hasIndexAttr, let typeSyntax = binding.typeAnnotation?.type else { continue }

            let resolved = resolveType(typeSyntax)

            // Resolve Index type from argument to @Index(...) default to .tag
            let attrs = varDecl.attributes
            if let indexAttr =
                attrs
                .compactMap({ $0.as(AttributeSyntax.self) })
                .first(where: { attr in
                    attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Index"
                })
            {
                let resolvedIndexType =
                    indexAttr.arguments?
                    .description
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? "type: .tag"

                indexType =
                    resolvedIndexType.split(separator: ":").last?
                    .trimmingCharacters(in: .whitespaces) ?? ".tag"
            }

            // MARK: Schema + Proxy Generation
            switch resolved {
            case .Other(let typeName),
                .Optional(of: .Other(let typeName)):
                if typeName == "Date" {
                    scalarFields.append(
                        """
                        Field(name: "\(name)", alias: "\(name.alias())", jsonPath: "$.\(name)", indexType: \(indexType))
                        """)
                    staticFieldRefs.append(
                        makeStaticRefDecl(
                            pathComponent: name, typeName: "\(resolved)", indexType: indexType
                        )
                    )
                } else {
                    nestedSchemas.append(
                        """
                        [
                            Field(name: "\(name)", alias: "\(name.alias())", jsonPath: "$.\(name)",indexType: \(indexType), nestedSchema: (((\(typeName).self as Any.Type) as? _SchemaProvider.Type)?.schema))
                        ]
                        """
                    )
                    staticFieldRefs.append(
                        makeStaticRefDecl(
                            pathComponent: name, typeName: "\(resolved)", indexType: indexType
                        )
                    )
                }
            case .Array(let elementType),
                .Optional(of: .Array(let elementType)):
                if elementType.isScalar {
                    scalarFields.append(
                        """
                        Field(name: "\(name)", alias: "\(name.alias())", jsonPath: "$.\(name)[*]", indexType: \(indexType))
                        """)
                    staticFieldRefs.append(
                        makeStaticRefDecl(
                            pathComponent: name, typeName: "\(resolved)", indexType: indexType)
                    )
                } else {
                    nestedSchemas.append(
                        """
                        [
                            Field(name: "\(name)", alias: "\(name.alias())", jsonPath: "$.\(name)[*]", indexType: \(indexType), nestedSchema: (((\(elementType).self as Any.Type) as? _SchemaProvider.Type)?.schema))
                        ]
                        """)
                    staticFieldRefs.append(
                        makeStaticRefDecl(
                            pathComponent: name, typeName: "\(resolved)", indexType: indexType
                        )
                    )
                }
            case .Dictionary(key: _, value: .Other(let typeName)):
                // Dictionary where value is a nested JsonModel
                context.diagnose(
                    Diagnostic(
                        node: declaration._syntaxNode,
                        message: IndexingNotSupportedMessage(
                            "Indexing dictionaries of embedded JsonModels (e.g. [String: \(typeName)]) is not supported. Use an array instead.",
                            severity: .error
                        )
                    ))
            case .Dictionary(key: _, value: let valueType):
                // Dictionary where value is a scalar or non-JsonModel
                context.diagnose(
                    Diagnostic(
                        node: declaration._syntaxNode,
                        message: IndexingNotSupportedMessage(
                            "Indexing dictionaries of scalar values (e.g. [String: \(valueType)]) is not supported. Use an array instead.",
                            severity: .error
                        )
                    ))
            default:
                // Normal scalar field
                scalarFields.append(
                    """
                    Field(name: "\(name)", alias: "\(name.alias())", jsonPath: "$.\(name)", indexType: \(indexType))
                    """
                )
                staticFieldRefs.append(
                    makeStaticRefDecl(
                        pathComponent: name, typeName: "\(resolved)", indexType: indexType))
            }

        }

        // MARK: Memberwise Init + Codable Conformance
        let memberwiseInit = createMemberwiseInit(structDecl)

        // Collect stored properties
        let storedProps = declaration.memberBlock.members.compactMap {
            member -> (String, TypeSyntax)? in
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.first,
                let ident = binding.pattern.as(IdentifierPatternSyntax.self)
            else { return nil }

            // Skip static vars
            if varDecl.modifiers.contains(where: { $0.name.text == "static" }) == true {
                return nil
            }
            let type = binding.typeAnnotation?.type ?? TypeSyntax(stringLiteral: "Any")
            return (ident.identifier.text, type)
        }

        // CodingKeys
        let codingKeys = storedProps.map { (name, _) in
            "case \(name)"
        }.joined(separator: "\n    ")

        // init(from:)
        let decodableInit = createDecodableInit(structDecl, storedProps)

        // encode(to:)
        let encodeLines = storedProps.map { (name, type) in
            if type.description.hasSuffix("?") {
                return "try c.encodeIfPresent(\(name), forKey: .\(name))"
            } else {
                return "try c.encode(\(name), forKey: .\(name))"
            }
        }.joined(separator: "\n    ")

        // MARK: Declaration Assebmly
        let codableAndSchemaDecl: DeclSyntax = """
            \(raw: staticFieldRefs.joined(separator: "\n"))

            \(raw: memberwiseInit)

            enum CodingKeys: String, CodingKey {
                \(raw: codingKeys)
            }

            \(raw: decodableInit)

            public func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                \(raw: encodeLines)
            }

            public static let schema: [Field] = [
                \(raw: scalarFields.joined(separator: ",\n    "))
            ]
            \(raw: nestedSchemas.map { "+ \( $0 )" }.joined(separator: "\n"))
            """

        return [DeclSyntax(codableAndSchemaDecl)]

    }

    /// Attach root conformance for SchemaProvider
    ///
    /// Creates extension on base model to adhere to SchemaProvider protocol
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo decl: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = decl.as(StructDeclSyntax.self) else {
            return []
        }
        let typeName = structDecl.name.text

        let hasSchemaDecl: DeclSyntax = """
            extension \(raw: typeName): _SchemaProvider {}
            """

        guard let extensionDecl = hasSchemaDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }
        return [try ExtensionDeclSyntax(validating: extensionDecl)]

    }

}

/// Creates a public initializer declaration for a struct based on its stored properties.
///
/// This function analyzes a struct's member variables and generates an initializer that:
/// - Includes parameters for all non-static stored properties
/// - Adds default `nil` values for optional parameters
/// - Handles special property wrapper assignments for `@Index` and `@Id` attributes
/// - Assigns regular properties directly
///
/// - Parameters:
///    - structDecl: The struct declaration syntax node to analyze
/// - Returns: A `DeclSyntax` representing the generated public initializer
///
/// ## Example
///
/// Given this struct:
/// ```swift
/// @Model
/// struct User: JsonModel {
///     @Id var id: String
///     @Index var email: String
///     @Index(type: .numeric) var age: Int
///     var notes: [String]
///     var createdAt: Date
///
///     static let keyPrefix: String = "user"
/// }
/// ```
///
/// Generates this initializer:
/// ```swift
/// init(
///     id: String,
///     email: String,
///     age: Int,
///     notes: [String],
///     createdAt: Date
/// ) {
///     self.id = id = Id(wrappedValue: id)
///     self._email = Index(wrappedValue: name, type: .tag)
///     self._age = Index(wrappedValue: age, type: .numeric)
///     self.notes = notes
///     self.createdAt = createdAt
/// }
/// ````
func createMemberwiseInit(_ structDecl: StructDeclSyntax) -> DeclSyntax {
    // Build initializer parameter list + body
    var params: [String] = []
    var bodyLines: [String] = []

    for member in structDecl.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let identPattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            continue
        }
        let name = identPattern.identifier.text

        // Skip static vars
        if varDecl.modifiers.contains(where: { $0.name.text == "static" }) == true {
            continue
        }

        // Extract type
        guard let typeAnn = binding.typeAnnotation else { continue }
        let typeStr = typeAnn.type.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle default alue (only add = nil for optionals)
        let defaultVal: String = typeStr.hasSuffix("?") ? " = nil" : ""

        // Add init to signature
        params.append("\(name): \(typeStr)\(defaultVal)")

        // Handle body assignment
        let attrs = varDecl.attributes

        if let indexAttr =
            attrs
            .compactMap({ $0.as(AttributeSyntax.self) })
            .first(where: { attr in
                attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Index"
            })
        {
            // Grab argument inside @Index(...) defaults to .tag
            let indexArg =
                indexAttr.arguments?
                .description
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "type: .tag"

            bodyLines.append("self._\(name) = Index(wrappedValue: \(name), \(indexArg))")
        } else if attrs.contains(where: {
            $0.as(AttributeSyntax.self)?
                .attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Id"
        }) {

            bodyLines.append("self._\(name) = Id(wrappedValue: \(name))")
        } else {
            bodyLines.append("self.\(name) = \(name)")
        }
    }

    let paramsJoined: String = params.joined(separator: ",\n    ")
    let bodyJoined: String = bodyLines.joined(separator: "\n    ")

    let initDecl: DeclSyntax = """
        public init(
            \(raw: paramsJoined)
        ) {
            \(raw: bodyJoined)
        }
        """
    return initDecl
}

/// Creates a initializer declaration for conformance with Decoable - init(from decoder: Decoder)
///
/// This function analyzes a struct's member variables and generates an initializer that:
/// - Includes parameters for all non-static stored properties
/// - Adds default `nil` values for optional parameters
/// - Handles special property wrapper assignments for `@Index` and `@Id` attributes
/// - Assigns regular properties directly
///
/// - Parameters:
///    - structDecl: The struct declaration syntax node to analyze
/// - Returns: A `DeclSyntax` representing the generated public initializer
///
/// ## Example
///
/// Given this struct:
/// ```swift
/// @Model
/// struct User: JsonModel {
///     @Id var id: String
///     @Index var email: String
///     @Index(type: .numeric) var age: Int
///     var notes: [String]
///     var createdAt: Date
///
///     static let keyPrefix: String = "user"
/// }
/// ```
///
/// Generates this initializer:
/// ```swift
/// init(from decoder: Decoder) throws {
///     let c = try decoder.container(keyedBy: CodingKeys.self)
///     let idDecoded = try c.decode(String.self, forKey: .id)
///     let emailDecoded = try c.decode(String.self, forKey: .email)
///     let ageDecoded = try c.decode(Int.self, forKey: .age)
///     let notesDecoded = try c.decode([String].self, forKey: .notes)
///     let createdAtDecoded = try c.decode(Date.self, forKey: .createdAt)
///
///     self._id = Id(wrappedValue: idDecoded)
///     self._email = Index(wrappedValue: emailDecoded, type: .tag)
///     self.age = ageDecoded
///     self.notes = notesDecoded
///     self.createdAt = createdAtDecoded
/// }
///
/// ```
func createDecodableInit(_ structDecl: StructDeclSyntax, _ storedProps: [(String, TypeSyntax)])
    -> DeclSyntax
{
    // Build initializer parameter list + body
    var params: [String] = []
    var bodyLines: [String] = []

    let decodeLines = storedProps.map { (name, type) in
        if type.description.hasSuffix("?") {
            return
                "let \(name)Decoded = try c.decodeIfPresent(\(type.description.dropLast()).self, forKey: .\(name))"
        } else {
            return "let \(name)Decoded = try c.decode(\(type).self, forKey: .\(name))"
        }
    }.joined(separator: "\n    ")

    for member in structDecl.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let identPattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            continue
        }
        let name = identPattern.identifier.text

        // Skip static vars
        if varDecl.modifiers.contains(where: { $0.name.text == "static" }) == true {
            continue
        }

        // Extract type
        guard let typeAnn = binding.typeAnnotation else { continue }
        let typeStr = typeAnn.type.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle default alue (only add = nil for optionals)
        let defaultVal: String = typeStr.hasSuffix("?") ? " = nil" : ""

        // Add init to signature
        params.append("\(name): \(typeStr)\(defaultVal)")

        // Handle body assignment
        let attrs = varDecl.attributes

        if let indexAttr =
            attrs
            .compactMap({ $0.as(AttributeSyntax.self) })
            .first(where: { attr in
                attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Index"
            })
        {
            // Grab argument inside @Index(...) defaults to .tag
            let indexArg =
                indexAttr.arguments?
                .description
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "type: .tag"

            bodyLines.append("self._\(name) = Index(wrappedValue: \(name)Decoded, \(indexArg))")
        } else if attrs.contains(where: {
            $0.as(AttributeSyntax.self)?
                .attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Id"
        }) {

            bodyLines.append("self._\(name) = Id(wrappedValue: \(name)Decoded)")
        } else {
            bodyLines.append("self.\(name) = \(name)Decoded")
        }
    }

    //    let paramsJoined: String = params.joined(separator: ",\n    ")
    let bodyJoined: String = bodyLines.joined(separator: "\n    ")

    let initDecl: DeclSyntax = """
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            \(raw: decodeLines)

            \(raw: bodyJoined)
        }
        """
    return initDecl
}

// MARK: Type Resolve

/// A simplified representation of the member's "base type"
// swift-format-ignore
indirect enum ResolvedType {
    case String
    case Int
    case Double
    case Float
    case Bool
    case Array(of: ResolvedType)
    case Dictionary(key: ResolvedType, value: ResolvedType)
    case Coordinate
    case Optional(of: ResolvedType)
    case Other(String)
}

extension ResolvedType: CustomStringConvertible {
    var description: String {
        switch self {
        case .String: return "String"
        case .Int: return "Int"
        case .Double: return "Double"
        case .Float: return "Float"
        case .Bool: return "Bool"
        case .Array(let element): return "[\(element)]"
        case .Dictionary(let key, let value): return "[\(key): \(value)]"
        case .Coordinate: return "Coordinate"
        case .Optional(let wrapped): return "\(wrapped)?"
        case .Other(let name): return name
        }
    }
}

extension ResolvedType {
    /// Returns true if the type represents a scalar value suitable for direct indexing.
    var isScalar: Bool {
        switch self {
        case .String, .Int, .Double, .Float, .Bool:
            return true
        case .Optional(let wrapped):
            return wrapped.isScalar
        case .Array(let element):
            return element.isScalar
        default:
            return false
        }
    }

    /// Returns the scalar's name for use in macro emission, if applicable.
    var scalarName: String? {
        switch self {
        case .String: return "String"
        case .Int: return "Int"
        case .Double: return "Double"
        case .Float: return "Float"
        case .Bool: return "Bool"
        case .Optional(let wrapped): return wrapped.scalarName
        case .Array(let element): return element.scalarName
        default: return nil
        }
    }
}

/// Walk the `TypeSyntax` tree to normalize it
/// - Parameters:
///    - type: type to resolve SimpleType from
/// - Returns: SimpleType
func resolveType(_ type: TypeSyntax) -> ResolvedType {
    if let simple = type.as(IdentifierTypeSyntax.self) {
        switch simple.name.text {
        case "String": return .String
        case "Int": return .Int
        case "Double": return .Double
        case "Float": return .Float
        case "Bool": return .Bool
        case "Coordinate": return .Coordinate
        default: return .Other(simple.name.text)
        }
    }

    if let opt = type.as(OptionalTypeSyntax.self) {
        return .Optional(of: resolveType(opt.wrappedType))
    }

    if let arr = type.as(ArrayTypeSyntax.self) {
        return .Array(of: resolveType(arr.element))
    }

    if let dict = type.as(DictionaryTypeSyntax.self) {
        return .Dictionary(
            key: resolveType(dict.key),
            value: resolveType(dict.value)
        )
    }

    if let member = type.as(MemberTypeSyntax.self) {
        return .Other(member.description)
    }

    if let specialize = GenericSpecializationExprSyntax(type),
        specialize.expression.description.trimmingCharacters(in: .whitespaces) == "Array",
        let firstArg = specialize.genericArgumentClause.arguments.first
    {
        // Correctly unwrap the argument and cast it to TypeSyntax
        if let genericArgumentType = firstArg.argument.as(TypeSyntax.self) {
            return .Array(of: resolveType(genericArgumentType))
        }
    }

    return .Other(type.description)
}

/// A diagnostic message used during macro expansion to report unsupported indexing patterns.
///
/// `IndexingNotSupportedMessage` conforms to `DiagnosticMessage` and allows
/// the macro system to surface clear compiler diagnostics when a user
/// attempts to index a type that Redis/RediSearch cannot handle (such as
/// dictionaries with arbitrary keys).
struct IndexingNotSupportedMessage: DiagnosticMessage {
    let message: String
    let severity: DiagnosticSeverity
    let diagnosticID: MessageID

    init(_ message: String, severity: DiagnosticSeverity = .error) {
        self.message = message
        self.severity = severity
        self.diagnosticID = MessageID(domain: "RedisOM", id: "InvalidDictionaryIndex")
    }
}
