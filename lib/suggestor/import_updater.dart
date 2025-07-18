import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

class ImportUpdater extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  final Map<String, String> _importReplacements = {
    'package:flutter/material.dart':
        'package:flutter/material.dart', // No cambiar
    'package:http/http.dart': 'package:http/http.dart', // No cambiar
    // Ejemplos de imports obsoletos
    'package:old_package/old_package.dart':
        'package:new_package/new_package.dart',
    'dart:html': 'dart:html', // Ejemplo: podría necesitar actualización
  };

  @override
  void visitImportDirective(ImportDirective node) {
    super.visitImportDirective(node);

    final uri = node.uri.stringValue;
    if (uri != null && _importReplacements.containsKey(uri)) {
      final replacement = _importReplacements[uri]!;

      if (uri != replacement) {
        yieldPatch(
          "'$replacement'",
          node.uri.offset,
          node.uri.end,
        );
      }
    }
  }
}
