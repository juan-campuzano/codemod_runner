import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

class DeprecatedCodeRemover extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  @override
  void visitDeclaration(Declaration node) {
    super.visitDeclaration(node);

    // Verificar si tiene la anotación @deprecated
    if (_isDeprecated(node)) {
      // Remover toda la declaración
      yieldPatch(
        '',
        node.offset,
        node.end,
      );
    }
  }

  /// Verifica si un nodo tiene la anotación @deprecated
  bool _isDeprecated(AnnotatedNode node) {
    return node.metadata.any((annotation) {
      final name = annotation.name.name.toLowerCase();
      return name == 'deprecated' || name == 'Deprecated';
    });
  }
}
