import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

class ObsoleteMethodReplacer extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  /// Mapa de métodos obsoletos a sus reemplazos
  final Map<String, String> _methodReplacements = {
    'setState': 'setState', // Ejemplo: no cambiar
    'initState': 'initState', // Ejemplo: no cambiar
    'dispose': 'dispose', // Ejemplo: no cambiar
    // Ejemplos reales de métodos obsoletos
    'deprecated_method': 'new_method',
    'oldApiCall': 'newApiCall',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final methodName = node.methodName.name;

    // Verificar si el método está en nuestra lista de reemplazos
    if (_methodReplacements.containsKey(methodName)) {
      final replacement = _methodReplacements[methodName]!;

      if (methodName != replacement) {
        // Crear patch para reemplazar el nombre del método
        yieldPatch(
          replacement,
          node.methodName.offset,
          node.methodName.end,
        );
      }
    }
  }
}
