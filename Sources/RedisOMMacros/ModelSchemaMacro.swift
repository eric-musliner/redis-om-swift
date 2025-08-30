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
/// ```
///
/// - Note: Only stored properties annotated with ``Index`` or ``AutoID``
///   are included in the schema. Other properties are ignored.
public struct ModelSchemaMacro: MemberMacro {
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
        var fieldEntries: [String] = []
        // var fields: [(name: String, indexType: String)] = []

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

            if hasIndexAttr, let typeSyntax = binding.typeAnnotation?.type {
                let resolved = resolveType(typeSyntax)
                let indexType = inferIndexType(resolved)

                let entry = """
                    Field(name: "\(name)", type: "\(resolved)", indexType: .\(indexType))
                    """
                fieldEntries.append(entry)
            }
        }
        let schemaDecl: DeclSyntax = """
            public static let schema: [Field] = [
                \(raw: fieldEntries.joined(separator: ",\n"))
            ]
            """

        return [DeclSyntax(schemaDecl)]

    }
}

/// A simplified representation of the member's "base type"
// swift-format-ignore
indirect enum SimpleType {
    case String
    case Int
    case Double
    case Float
    case Bool
    case Array(of: SimpleType)
    case Dictionary(key: SimpleType, value: SimpleType)
    case Coordinate
    case Other(String)
}

extension SimpleType: CustomStringConvertible {
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
func resolveType(_ type: TypeSyntax) -> SimpleType {
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

    return .Other(
        type.description.trimmingCharacters(in: .whitespacesAndNewlines)
    )

}

/// Infer RediSearch IndexType
/// - Parameters:
///    - simple: simple type to infer index type from
/// - Returns: IndexType
func inferIndexType(_ simple: SimpleType) -> IndexType {
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
