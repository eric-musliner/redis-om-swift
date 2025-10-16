import SwiftSyntaxMacros

@attached(member, names: arbitrary)
@attached(extension, conformances: _SchemaProvider)
public macro Model() =
    #externalMacro(module: "RedisOMMacros", type: "ModelMacro")
