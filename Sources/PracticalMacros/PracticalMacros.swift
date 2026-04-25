
import Foundation


@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "PracticalMacrosMacros", type: "StringifyMacro")

@freestanding(expression)
public macro URL(_ stringLiteral: String) -> URL = #externalMacro(module: "PracticalMacrosMacros", type: "URLMacro")

@attached(member, names: named(id))
@attached(extension, conformances: Identifiable)
public macro CaseIdentifiable() = #externalMacro(module: "PracticalMacrosMacros", type: "CaseIdentifiableMacro")
