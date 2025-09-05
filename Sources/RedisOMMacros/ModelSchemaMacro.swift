import Foundation
import RedisOMCore
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that synthesizes a RedisOM schema definition for a model type.
///
/// Apply `@ModelSchema` to a `struct` or `class` that defines stored properties
/// annotated with property macros such as ``Index`` or ``AutoID``. The macro
/// will expand the type with a static `schema` definition describing all fields,
/// their Swift type, and their Redis index configuration.
///
/// The generated schema is used by RedisOM to automatically create indexes
/// and map Redis data back into your Swift model.
///
/// Example:
///
/// ```swift
/// @ModelSchema
/// struct User: JsonModel {
///     @AutoID var id: String
///     @Index var email: String
///     @Index var age: Int
///     var notes: [String]
/// }
/// ```
///
/// Expands to:
///
/// ```swift
/// extension User {
///     public static let schema: [Field] = [
///         Field(name: "id", type: "String", indexType: .tag),
///         Field(name: "email", type: "String", indexType: .text),
///         Field(name: "age", type: "Int", indexType: .numeric),
///     ]
/// }
///
/// extension User: _SchemaProvider {
/// }
/// ```
///
/// - Note: Only stored properties annotated with ``Index`` or ``AutoID``
///   are included in the schema. Other properties are ignored.
public struct ModelSchemaMacro: MemberMacro, ExtensionMacro {
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
        var scalarFields: [String] = []
        var nestedSchemas: [String] = []

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

            // Annotated with Index or AutoID wrapper
            let hasIndexAttr = attributes.contains {
                if let attr = $0.as(AttributeSyntax.self) {
                    let name = attr.attributeName.description
                        .trimmingCharacters(in: .whitespaces)
                    return name == "Index" || name == "AutoID"
                }
                return false
            }
            guard hasIndexAttr, let typeSyntax = binding.typeAnnotation?.type else { continue }

            let resolved = resolveType(typeSyntax)
            let indexType = inferIndexType(resolved)

            switch resolved {
            case .Other(let typeName):
                if typeName == "Date" {
                    scalarFields.append(
                        """
                        Field(name: "\(name)", type: "\(resolved)", indexType: .\(indexType))
                        """)
                } else {
                    nestedSchemas.append(
                        """
                        (((\(typeName).self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                            Field(name: "\(name).\\(f.name)", type: f.type, indexType: f.indexType)
                        } ?? [] )
                        """)
                }
            case .Array(of: .Other(let typeName)):
                // Array of nested models
                nestedSchemas.append(
                    """
                    \(typeName).schema.map { f in
                        Field(name: "\(name).\\(f.name)", type: f.type, indexType: f.indexType)
                    }
                    """)
            case .Dictionary(key: _, value: .Other(let typeName)):
                // Dictionary where value is a nested JsonModel
                nestedSchemas.append(
                    """
                    (((\(typeName).self as Any.Type) as? _SchemaProvider.Type )?.schema.map { f in
                        Field(name: "\(name).\\(f.name)", type: f.type, indexType: f.indexType)
                    } ?? [
                        Field(name: "\(name)", type: "[String: \(typeName)]", indexType: .text)
                    ])
                    """)
            case .Dictionary(key: _, value: let valueType):
                // Dictionary where value is a scalar or non-JsonModel
                scalarFields.append(
                    """
                    Field(name: "\(name)", type: "[String: \(valueType)]", indexType: .text)
                    """)
            default:
                // Normal scalar field
                scalarFields.append(
                    """
                    Field(name: "\(name)", type: "\(resolved)", indexType: .\(indexType))
                    """)
            }

        }
        let schemaDecl: DeclSyntax = """
            public static let schema: [Field] = [
                \(raw: scalarFields.joined(separator: ",\n"))
            ]
            \(raw: nestedSchemas.map { "+ \( $0 )" }.joined(separator: "\n"))
            """

        return [DeclSyntax(schemaDecl)]

    }

    // Attach root conformance
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
        case .Other(let name): return name
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
        return resolveType(opt.wrappedType)
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

/// Infer RediSearch IndexType
/// - Parameters:
///    - simple: resovled type to infer index type from
/// - Returns: IndexType
func inferIndexType(_ simple: ResolvedType) -> IndexType {
    switch simple {
    case .String:
        return .text
    case .Int, .Double, .Float:
        return .numeric
    case .Bool:
        return .tag
    case .Other("Date"), .Other("DateTime"):
        return .numeric
    case .Array(of: .Float), .Array(of: .Double):
        return .vector
    case .Array(let inner):
        // For arrays, fall back on the element type
        return inferIndexType(inner)
    case .Dictionary(_, let value):
        // For dicts, fall back on value type
        return inferIndexType(value)
    case .Coordinate:
        return .geo
    default:
        return .text
    }
}
