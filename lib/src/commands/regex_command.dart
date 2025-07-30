import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:codemod/codemod.dart';

import '../suggestor/suggestor.dart';

class RegexCommand extends Command<int> {
  @override
  String get name => 'regex';

  @override
  String get description => 'Run regex substitutions on files.';

  RegexCommand() {
    argParser
      ..addOption(
        'pattern',
        abbr: 'p',
        help: 'The regex pattern to match.',
        mandatory: true,
      )
      ..addOption(
        'replacement',
        abbr: 'r',
        help: 'The replacement string for the matched pattern.',
        mandatory: true,
      )
      ..addOption(
        'files',
        abbr: 'f',
        help: 'List of files to apply the regex substitution on.',
        mandatory: true,
      );
  }

  @override
  Future<int> run() async {
    final pattern = argResults!['pattern'] as String;
    final replacement = argResults!['replacement'] as String;
    final files = (argResults!['files'] as String).split(',');

    if (files.isEmpty) {
      print('No files provided for regex substitution.');
      return 1;
    }

    exitCode = await runInteractiveCodemod(
      files,
      RegexSuggestor(pattern, replacement).regexSubstituter,
    );

    return exitCode;
  }
}
