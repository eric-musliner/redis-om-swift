import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct RedisOMPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModelSchemaMacro.self
    ]

}
