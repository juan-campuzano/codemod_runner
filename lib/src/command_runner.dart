import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';

import 'commands/commands.dart';

const String executableName = 'modkit';
const String description =
    'A Dart package to run codemods based on migration rules.';

class CommandRunner extends CompletionCommandRunner<int> {
  CommandRunner() : super(executableName, description) {
    addCommand(
      MigrateCommand(),
    );
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);

      return await runCommand(topLevelResults) ?? exitCode;
    } on UsageException catch (e) {
      stderr.writeln(e.message);
      stderr.writeln('Run "$executableName help" for usage information.');
      return 64;
    } catch (e) {
      stderr.writeln('An unexpected error occurred: $e');
      return 1;
    }
  }
}
