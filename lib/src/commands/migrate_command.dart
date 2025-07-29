import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:codemod/codemod.dart';
import 'package:glob/glob.dart';

import '../suggestor/suggestor.dart';

class MigrateCommand extends Command<int> {
  MigrateCommand() {
    argParser
      ..addOption(
        'rules',
        abbr: 'r',
        help: 'Path to the JSON rules file for migration.',
      )
      ..addOption(
        'files',
        abbr: 'f',
        help: 'Glob pattern to specify target files for migration.',
        defaultsTo: 'lib/**.dart',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Directory path to search for Dart files.',
      );
  }

  @override
  String get description => 'Run migration based on JSON rules file.';

  @override
  String get name => 'migrate';

  @override
  Future<int> run() async {
    final args = argResults;
    final rulesFile = _getRulesFile(args);
    final targetFiles = _getTargetFiles(args);

    print('Starting migration based on JSON file...');
    print('🗃️ Rules file: $rulesFile');
    print('🎯 Target files: ${targetFiles.join('\n')}');

    try {
      validateRulesFile(rulesFile);

      final suggestor = await JsonRulesSuggestor.fromFile(rulesFile);

      final exitCode = await runInteractiveCodemod(
        targetFiles,
        suggestor,
        // args: dryRun ? [...args, '--dry-run'] : args,
      );

      if (exitCode == 0) {
        print('✅ Migration completed successfully!');
      } else {
        print('❌ There were some errors migrating files.');
      }
    } catch (e) {
      print('❌ Error processing rules file: $e');
      exit(1);
    }
    return exitCode;
  }

  String _getRulesFile(ArgResults? args) {
    final rulesFileOption = args?['rules'] as String?;

    if (rulesFileOption != null && rulesFileOption.isNotEmpty) {
      final file = File(rulesFileOption);
      if (file.existsSync()) {
        return file.path;
      } else {
        print('❌ Rules file not found: $rulesFileOption');
        exit(1);
      }
    }

    const defaultFiles = [
      'migration_rules.json',
      'rules/migration.json',
      'codemod_rules.json',
    ];

    for (final file in defaultFiles) {
      if (File(file).existsSync()) {
        return file;
      }
    }

    print('❌ Rules file not found.');
    print(
        'Usage: dart run tool/json_migration.dart --rules=migration_rules.json');
    print('Or create one of these files: ${defaultFiles.join(', ')}');
    exit(1);
  }

  Iterable<String> _getTargetFiles(ArgResults? args) {
    if (args?['files'] != null) {
      final filesOption = args?['files'] as String?;
      if (filesOption != null && filesOption.isNotEmpty) {
        return filePathsFromGlob(Glob(filesOption));
      }
    }

    if (args?['path'] != null) {
      final filesOption = args?['path'] as String?;
      if (filesOption != null && filesOption.isNotEmpty) {
        return filePathsFromGlob(Glob(filesOption));
      }
    }

    return filePathsFromGlob(Glob('lib/**.dart', recursive: true));
  }

  Future<void> validateRulesFile(String filePath) async {
    print('🔍 Validating rules file: $filePath');

    try {
      final suggestor = await JsonRulesSuggestor.fromFile(filePath);
      print('✅ Valid rules file');
      print('📊 Total rules: ${suggestor.rules.length}');

      final rulesByType = <String, int>{};
      for (final rule in suggestor.rules) {
        for (final change in rule.changes) {
          final type = change.kind.toString();
          rulesByType[type] = (rulesByType[type] ?? 0) + 1;
        }
      }

      print('📋 Change types:');
      rulesByType.forEach((type, count) {
        print('  - $type: $count');
      });
    } catch (e) {
      print('❌ Invalid rules file: $e');
      exit(1);
    }
  }

  Future<void> runMultipleRuleSets(
      List<String> ruleFiles, ArgResults? args) async {
    print('🚀 Running migration with multiple rule sets...');

    final targetFiles = _getTargetFiles(args);
    final suggestors = <Suggestor>[];

    for (final ruleFile in ruleFiles) {
      try {
        final suggestor = await JsonRulesSuggestor.fromFile(ruleFile);
        suggestors.add(suggestor);
        print('✅ Rules loaded from: $ruleFile');
      } catch (e) {
        print('❌ Error loading $ruleFile: $e');
      }
    }

    if (suggestors.isEmpty) {
      print('❌ No rules could be loaded.');
      return;
    }

    final exitCode = await runInteractiveCodemodSequence(
      targetFiles,
      suggestors,
      // args: args,
    );

    if (exitCode == 0) {
      print('✅ Multi-rule migration completed!');
    }
  }
}
