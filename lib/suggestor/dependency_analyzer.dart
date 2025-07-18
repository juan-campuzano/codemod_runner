import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

class DependencyAnalyzer extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  @override
  bool shouldResolveAst(FileContext context) => true;

  final Set<String> _foundDependencies = {};

  @override
  void visitImportDirective(ImportDirective node) {
    super.visitImportDirective(node);

    final uri = node.uri.stringValue;
    if (uri != null) {
      _foundDependencies.add(uri);

      // Analizar si el import es de una versión obsoleta
      if (_isObsoletePackage(uri)) {
        final suggestion = _getSuggestionForObsoletePackage(uri);
        if (suggestion != null) {
          // Crear un comentario con la sugerencia
          yieldPatch(
            '// TODO: Consider updating to $suggestion\n',
            node.offset,
            node.offset,
          );
        }
      }
    }
  }

  bool _isObsoletePackage(String uri) {
    // Lista de paquetes conocidos como obsoletos
    final obsoletePackages = [
      'package:flutter_webview_plugin/',
      'package:location/location.dart',
      'package:permission_handler/',
    ];

    return obsoletePackages.any((pkg) => uri.startsWith(pkg));
  }

  String? _getSuggestionForObsoletePackage(String uri) {
    // Sugerencias para paquetes obsoletos
    final suggestions = {
      'package:flutter_webview_plugin/': 'package:webview_flutter/',
      'package:location/location.dart': 'package:geolocator/',
      'package:permission_handler/':
          'package:permission_handler/ (latest version)',
    };

    for (final entry in suggestions.entries) {
      if (uri.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }
}
