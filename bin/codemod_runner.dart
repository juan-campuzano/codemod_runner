import 'dart:io';
import 'package:codemod/codemod.dart';
import 'package:codemod_runner/codemod_runner.dart';
import 'package:glob/glob.dart';

void main(List<String> args) async {
  await runYamlMigration(args);
}

Future<void> runYamlMigration(List<String> args) async {
  final rulesFile = _getRulesFile(args);
  final targetFiles = _getTargetFiles(args);
  final dryRun = args.contains('--dry-run');

  print('🚀 Iniciando migración basada en reglas YAML...');
  print('📋 Archivo de reglas: $rulesFile');
  print('📁 Archivos objetivo: ${targetFiles.length}');

  if (dryRun) {
    print('🔍 Modo dry-run activado');
  }

  try {
    final suggestor = await YamlRulesSuggestor.fromFile(rulesFile);

    final exitCode = await runInteractiveCodemod(
      targetFiles,
      suggestor,
      args: dryRun ? [...args, '--dry-run'] : args,
    );

    if (exitCode == 0) {
      print('✅ Migración completada exitosamente!');
    } else {
      print('❌ Hubo errores durante la migración');
    }
  } catch (e) {
    print('❌ Error al procesar archivo de reglas: $e');
    exit(1);
  }
}

String _getRulesFile(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--rules=')) {
      return arg.substring(8);
    }
  }

  const defaultFiles = [
    'migration_rules.yaml',
    'rules/migration.yaml',
    'codemod_rules.yaml',
  ];

  for (final file in defaultFiles) {
    if (File(file).existsSync()) {
      return file;
    }
  }

  print('❌ No se encontró archivo de reglas.');
  print('Uso: dart run tool/yaml_migration.dart --rules=migration_rules.yaml');
  print('O crea uno de estos archivos: ${defaultFiles.join(', ')}');
  exit(1);
}

Iterable<String> _getTargetFiles(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--files=')) {
      final pattern = arg.substring(8);
      return filePathsFromGlob(Glob(pattern, recursive: true));
    }
  }

  for (final arg in args) {
    if (arg.startsWith('--path=')) {
      final path = arg.substring(7);
      return filePathsFromGlob(Glob('$path/**.dart', recursive: true));
    }
  }

  return filePathsFromGlob(Glob('lib/**.dart', recursive: true));
}

Future<void> runMultipleRuleSets(
    List<String> ruleFiles, List<String> args) async {
  print('🚀 Ejecutando migración con múltiples conjuntos de reglas...');

  final targetFiles = _getTargetFiles(args);
  final suggestors = <Suggestor>[];

  for (final ruleFile in ruleFiles) {
    try {
      final suggestor = await YamlRulesSuggestor.fromFile(ruleFile);
      suggestors.add(suggestor);
      print('✅ Reglas cargadas desde: $ruleFile');
    } catch (e) {
      print('❌ Error al cargar $ruleFile: $e');
    }
  }

  if (suggestors.isEmpty) {
    print('❌ No se pudieron cargar reglas');
    return;
  }

  final exitCode = await runInteractiveCodemodSequence(
    targetFiles,
    suggestors,
    args: args,
  );

  if (exitCode == 0) {
    print('✅ Migración multi-reglas completada!');
  }
}

Future<void> validateRulesFile(String filePath) async {
  print('🔍 Validando archivo de reglas: $filePath');

  try {
    final suggestor = await YamlRulesSuggestor.fromFile(filePath);
    print('✅ Archivo de reglas válido');
    print('📊 Total de reglas: ${suggestor.rules.length}');

    final rulesByType = <String, int>{};
    for (final rule in suggestor.rules) {
      for (final change in rule.changes) {
        final type = change.kind.toString();
        rulesByType[type] = (rulesByType[type] ?? 0) + 1;
      }
    }

    print('📋 Tipos de cambios:');
    rulesByType.forEach((type, count) {
      print('  - $type: $count');
    });
  } catch (e) {
    print('❌ Error en archivo de reglas: $e');
    exit(1);
  }
}
