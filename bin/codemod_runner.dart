import 'dart:io';
import 'package:codemod/codemod.dart';
import 'package:codemod_runner/codemod_runner.dart';
import 'package:glob/glob.dart';

void main(List<String> args) async {
  final parsedArgs = _parseArguments(args);

  final dartFiles = filePathsFromGlob(
    Glob('lib/**.dart', recursive: true),
  );
  final pubspecFiles = filePathsFromGlob(
    Glob('**/pubspec.yaml', recursive: true),
  );

  final allFiles = [...dartFiles, ...pubspecFiles];

  if (parsedArgs.containsKey('dry-run')) {
    print('🔍 Ejecutando en modo dry-run...');

    final allSuggestors = aggregate(
      [
        PrintToDebugPrintSuggestor(),
        DependencyUpdaterSuggestor(),
        ObsoleteMethodReplacer(),
        VariableDeclarationUpdater(),
        DeprecatedCodeRemover(),
        ImportUpdater(),
      ],
    );

    exitCode = await runInteractiveCodemod(
      allFiles,
      allSuggestors,
      args: [...args, '--dry-run'],
    );
    return;
  }

  if (parsedArgs.containsKey('suggestor')) {
    await runSpecificSuggestor(parsedArgs['suggestor']!, args);
    return;
  }

  if (parsedArgs.containsKey('help')) {
    _printUsage();
    return;
  }

  print('🚀 Iniciando Data-Driven Fixes...');
  print('📁 Archivos a procesar: ${allFiles.length}');

  final phases = [
    _createBasicUpdatesPhase(),
    _createAstAnalysisPhase(),
    _createResolvedAstAnalysisPhase(),
  ];

  exitCode = await runInteractiveCodemodSequence(
    allFiles,
    phases,
    args: args,
  );

  if (exitCode == 0) {
    print('✅ Data-Driven Fixes completado exitosamente!');
  } else {
    print('❌ Hubo errores durante la ejecución');
  }
}

Suggestor _createBasicUpdatesPhase() {
  return aggregate([
    PrintToDebugPrintSuggestor(),
    DependencyUpdaterSuggestor(),
  ]);
}

Suggestor _createAstAnalysisPhase() {
  return aggregate([
    ObsoleteMethodReplacer(),
    VariableDeclarationUpdater(),
    DeprecatedCodeRemover(),
    ImportUpdater(),
  ]);
}

Suggestor _createResolvedAstAnalysisPhase() {
  return aggregate([
    ResolvedAstSuggestor(),
    DependencyAnalyzer(),
  ]);
}

Future<void> runSpecificSuggestor(
    String suggestorName, List<String> args) async {
  final dartFiles = filePathsFromGlob(Glob('lib/**.dart', recursive: true));

  Suggestor? suggestor;

  switch (suggestorName) {
    case 'print-to-debug':
      suggestor = PrintToDebugPrintSuggestor();
      break;
    case 'update-dependencies':
      suggestor = DependencyUpdaterSuggestor();
      break;
    case 'replace-obsolete-methods':
      suggestor = ObsoleteMethodReplacer();
      break;
    case 'update-variables':
      suggestor = VariableDeclarationUpdater();
      break;
    case 'remove-deprecated':
      suggestor = DeprecatedCodeRemover();
      break;
    case 'update-imports':
      suggestor = ImportUpdater();
      break;
    case 'resolved-analysis':
      suggestor = ResolvedAstSuggestor();
      break;
    case 'analyze-dependencies':
      suggestor = DependencyAnalyzer();
      break;
    default:
      print('Suggestor no encontrado: $suggestorName');
      print('Suggestors disponibles:');
      print('  - print-to-debug');
      print('  - update-dependencies');
      print('  - replace-obsolete-methods');
      print('  - update-variables');
      print('  - remove-deprecated');
      print('  - update-imports');
      print('  - resolved-analysis');
      print('  - analyze-dependencies');
      return;
  }

  exitCode = await runInteractiveCodemod(
    dartFiles,
    suggestor,
    args: args,
  );
}

Future<void> runDryMode(List<String> args) async {
  print('🔍 Ejecutando en modo dry-run...');

  final dartFiles = filePathsFromGlob(Glob('lib/**.dart', recursive: true));
  final pubspecFiles =
      filePathsFromGlob(Glob('**/pubspec.yaml', recursive: true));

  final allSuggestors = aggregate([
    PrintToDebugPrintSuggestor(),
    DependencyUpdaterSuggestor(),
    ObsoleteMethodReplacer(),
    VariableDeclarationUpdater(),
    DeprecatedCodeRemover(),
    ImportUpdater(),
  ]);

  int totalFiles = 0;
  int filesWithChanges = 0;
  int totalPatches = 0;

  final allFiles = [
    ...dartFiles.map((path) => File(path)),
    ...pubspecFiles.map((path) => File(path)),
  ];

  print('📊 Analizando archivos...');

  for (final file in allFiles) {
    if (await file.exists()) {
      totalFiles++;
      print('  📄 ${file.path}');
    }
  }

  print('\n📊 Resumen:');
  print('  📁 Archivos encontrados: $totalFiles');
  print('\n💡 Para ver los cambios específicos, ejecuta:');
  print('  dart run tool/codemod.dart --dry-run');
  print('\n💡 Para aplicar los cambios, ejecuta:');
  print('  dart run tool/codemod.dart');
}

int _getLineNumber(String source, int offset) {
  return source.substring(0, offset).split('\n').length;
}

Map<String, String> _parseArguments(List<String> args) {
  final parsed = <String, String>{};

  for (final arg in args) {
    if (arg.startsWith('--')) {
      final parts = arg.substring(2).split('=');
      if (parts.length == 2) {
        parsed[parts[0]] = parts[1];
      } else {
        parsed[parts[0]] = 'true';
      }
    }
  }

  return parsed;
}

void _printUsage() {
  print('''
Data-Driven Fixes para Dart usando codemod

Uso: dart run tool/codemod.dart [opciones]

Opciones:
  --help                    Muestra esta ayuda
  --dry-run                 Muestra qué cambiaría sin aplicar cambios
  --suggestor=NOMBRE        Ejecuta un suggestor específico

Suggestors disponibles:
  print-to-debug            Convierte print() a debugPrint()
  update-dependencies       Actualiza dependencias en pubspec.yaml
  replace-obsolete-methods  Reemplaza métodos obsoletos
  update-variables          Convierte 'var' a tipos explícitos
  remove-deprecated         Remueve código marcado como @deprecated
  update-imports            Actualiza imports obsoletos
  resolved-analysis         Análisis con AST resuelto
  analyze-dependencies      Analiza dependencias y sugiere actualizaciones

Ejemplos:
  dart run tool/codemod.dart
  dart run tool/codemod.dart --dry-run
  dart run tool/codemod.dart --suggestor=print-to-debug
''');
}
