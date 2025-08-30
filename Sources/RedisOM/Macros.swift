import SwiftSyntaxMacros

@attached(member, names: named(schema))
public macro ModelSchema() =
    #externalMacro(module: "RedisOMMacros", type: "ModelSchemaMacro")
