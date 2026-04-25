import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation
import SwiftDiagnostics

public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct URLMacro: ExpressionMacro {
    struct URLMacroDiagnostic: DiagnosticMessage {
        let message: String
        let diagnosticID: SwiftDiagnostics.MessageID
        let severity: SwiftDiagnostics.DiagnosticSeverity
        
        static let expectedStringLiteral = URLMacroDiagnostic(
            message: "The #URL macro requires a static string literal.",
            diagnosticID: MessageID(domain: "PracticalMacros.URLMacro", id: "expectedStringLiteral"),
            severity: .error
        )
        
        static func invalidAbsoluteURL(_ value: String) -> URLMacroDiagnostic {
            URLMacroDiagnostic(
                message: "'\(value)' is not a valid absolute URL.",
                diagnosticID: MessageID(domain: "PracticalMacros.URLMacro", id: "invalidAbsoluteURL"),
                severity: .error
            )
        }
    }
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> SwiftSyntax.ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("Expected one argument")
        }
        guard let literal = argument.as(StringLiteralExprSyntax.self),
              literal.segments.count == 1,
              let segment = literal.segments.first?.as(StringSegmentSyntax.self) else {
            context.diagnose(Diagnostic(node: argument, message: URLMacroDiagnostic.expectedStringLiteral))
            return "Foundation.URL(string: \"https://example.com\")!"
        }
        let urlString = segment.content.text
        guard let url = URL(string: urlString),
              url.scheme != nil,
              url.host != nil else {
            context.diagnose(Diagnostic(node: argument, message: URLMacroDiagnostic.invalidAbsoluteURL(urlString)))
            return "Foundation.URL(string: \"https://example.com\")!"
        }
        return "URL(string: \(literal))!"
    }
}

public struct CaseIdentifiableMacro: MemberMacro, ExtensionMacro {
    
    
    struct CaseIdentfiableDiagnostic: DiagnosticMessage {
        let message: String
        let diagnosticID: SwiftDiagnostics.MessageID
        let severity: SwiftDiagnostics.DiagnosticSeverity
        
        static let onlyAppliesToEnums = CaseIdentfiableDiagnostic(
            message: "@CaseIdentifiable only applies to enums",
            diagnosticID: MessageID(
                domain: "PracticalMacroMacros.CaseIdentifiableMacro",
                id: "onlyAppliesToEnums"
            ),
            severity: .error
        )

        static let requiresAtLeastOneCase = CaseIdentfiableDiagnostic(
            message: "@CaseIdentifiable requires an enum with at least one case",
            diagnosticID: MessageID(
                domain: "PracticalMacroMacros.CaseIdentifiableMacro",
                id: "requiresAtLeastOneCase"
            ),
            severity: .error
        )

    }
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDeclaration = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(declaration),
                    message: CaseIdentfiableDiagnostic.onlyAppliesToEnums
                )
            )
            return []
        }
        let cases = declaration.memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)
        }
        let caseElements = cases.flatMap(\.elements)
        guard !caseElements.isEmpty else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(enumDeclaration.name),
                    message: CaseIdentfiableDiagnostic.requiresAtLeastOneCase
                )
            )
            return []
        }
        let switchCases = caseElements.map { caseElement in
            let caseName = caseElement.name.text
            return
                """
                case .\(caseName)
                    "\(caseName)"
                """
        }.joined(separator: "\n")
        let idProperty: DeclSyntax =
        """
        public var id: String {
            switch self {
              \(raw: switchCases)
            }
        }
        """
        return [idProperty]
    }
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let enumDeclaration = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(declaration),
                    message: CaseIdentfiableDiagnostic.onlyAppliesToEnums
                )
            )
            return []
        }
        return [
            try ExtensionDeclSyntax("extension \(type.trimmed): Identifiable {}")
        ]
    }
}

@main
struct PracticalMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        URLMacro.self,
        CaseIdentifiableMacro.self
    ]
}
