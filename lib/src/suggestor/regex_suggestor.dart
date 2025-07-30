import 'package:codemod/codemod.dart';

class RegexSuggestor {
  final String regexPattern;
  final String replacement;

  RegexSuggestor(
    this.regexPattern,
    this.replacement,
  );

  Stream<Patch> regexSubstituter(FileContext context) async* {
    final RegExp pattern = RegExp(
      regexPattern,
      multiLine: true,
    );

    for (final match in pattern.allMatches(context.sourceText)) {
      final line = match.group(0);

      final String updated = line!.replaceAll(
        pattern,
        replacement,
      );

      yield Patch(updated, match.start, match.end);
    }
  }
}
