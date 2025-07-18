import 'package:codemod/codemod.dart';

/// Suggestor que reemplaza el uso de `debugPrint()` con `debugPrint()` para mejor debugging
class PrintToDebugPrintSuggestor {
  /// Patrón que encuentra llamadas a debugPrint()
  final RegExp _printPattern = RegExp(
    r'print\s*\(',
    multiLine: true,
  );

  Stream<Patch> call(FileContext context) async* {
    // Buscar todas las coincidencias de debugPrint() en el archivo
    for (final match in _printPattern.allMatches(context.sourceText)) {
      // Crear un patch que reemplaza 'debugPrint(' con 'debugPrint('
      yield Patch(
        'debugPrint(',
        match.start,
        match.end,
      );
    }

    // Agregar el import de flutter/foundation.dart si no existe
    if (!context.sourceText
            .contains("import 'package:flutter/foundation.dart'") &&
        _printPattern.hasMatch(context.sourceText)) {
      yield Patch(
        "import 'package:flutter/foundation.dart';\n",
        0,
        0,
      );
    }
  }
}

/// Suggestor que actualiza dependencias obsoletas
class DependencyUpdaterSuggestor {
  final Map<String, String> _dependencyUpdates = {
    r'http:\s*\^0\.13\.0': 'http: ^1.0.0',
    r'provider:\s*\^5\.0\.0': 'provider: ^6.0.0',
    r'shared_preferences:\s*\^2\.0\.0': 'shared_preferences: ^2.2.0',
  };

  Stream<Patch> call(FileContext context) async* {
    for (final entry in _dependencyUpdates.entries) {
      final pattern = RegExp(entry.key);
      for (final match in pattern.allMatches(context.sourceText)) {
        yield Patch(
          entry.value,
          match.start,
          match.end,
        );
      }
    }
  }
}
