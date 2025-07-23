import 'package:codemod_runner/src/codemod_runner.dart';

void main(List<String> args) async {
  await CodemodRunner().runYamlMigration(args);
}
