import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

class VariableDeclarationUpdater extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);

    // Ejemplo: cambiar 'var' por tipo explícito cuando sea posible
    final parent = node.parent;
    if (parent is VariableDeclarationList) {
      final keyword = parent.keyword;
      if (keyword != null && keyword.lexeme == 'var') {
        // Determinar el tipo basado en el inicializador
        final initializer = node.initializer;
        if (initializer != null) {
          String? suggestedType;

          if (initializer is StringLiteral) {
            suggestedType = 'String';
          } else if (initializer is IntegerLiteral) {
            suggestedType = 'int';
          } else if (initializer is DoubleLiteral) {
            suggestedType = 'double';
          } else if (initializer is BooleanLiteral) {
            suggestedType = 'bool';
          } else if (initializer is ListLiteral) {
            suggestedType = 'List';
          } else if (initializer is SetOrMapLiteral) {
            suggestedType = initializer.isMap ? 'Map' : 'Set';
          }

          if (suggestedType != null) {
            yieldPatch(
              suggestedType,
              keyword.offset,
              keyword.end,
            );
          }
        }
      }
    }
  }
}
