import SwiftSyntaxMacros

@attached(member, names: named(init), named(schema))
@attached(extension, conformances: _SchemaProvider)
public macro ModelSchema() =
    #externalMacro(module: "RedisOMMacros", type: "ModelSchemaMacro")
