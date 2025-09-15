import SwiftSyntaxMacros

@attached(
    member, names: named(init), named(schema), named(CodingKeys), named(init(from:)),
    named(encode(to:)))
@attached(extension, conformances: _SchemaProvider)
public macro ModelSchema() =
    #externalMacro(module: "RedisOMMacros", type: "ModelSchemaMacro")
