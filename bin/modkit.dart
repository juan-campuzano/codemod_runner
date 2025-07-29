import 'package:modkit/modkit.dart';

void main(List<String> args) async {
  await CommandRunner().runJsonMigration(args);
}
