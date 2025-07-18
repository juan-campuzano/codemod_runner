import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:codemod/codemod.dart';
import 'package:analyzer/dart/ast/ast.dart';

class ResolvedAstSuggestor extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  @override
  bool shouldResolveAst(FileContext context) => true;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final element = node.methodName.staticElement;
    if (element is MethodElement) {
      final library = element.library;

      if (library.source.uri.toString() == 'package:bds_mobile/material.dart') {
        _handleFlutterMaterialMethod(node, element);
      }
    }
  }

  void _handleFlutterMaterialMethod(
      MethodInvocation node, MethodElement element) {
    switch (element.name) {
      case 'deprecated_flutter_method':
        yieldPatch(
          'new_flutter_method',
          node.methodName.offset,
          node.methodName.end,
        );
        break;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);

    final element = node.staticElement;
    if (element is ClassElement) {
      final library = element.library;

      if (library.source.uri
          .toString()
          .startsWith('package:deprecated_package/')) {
        final className = element.name;
        final replacement = _getClassReplacement(className);

        if (replacement != null) {
          yieldPatch(
            replacement,
            node.offset,
            node.end,
          );
        }
      }
    }
  }

  String? _getClassReplacement(String className) {
    final replacements = {
      'OldWidget': 'NewWidget',
      'DeprecatedController': 'ModernController',
      'LegacyProvider': 'CurrentProvider',
    };

    return replacements[className];
  }
}
