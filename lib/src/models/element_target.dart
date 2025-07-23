import 'package:yaml/yaml.dart';

class ElementTarget {
  final List<String>? uris;
  final String? method;
  final String? inClass;
  final String? className;
  final String? field;
  final String? variable;
  final String? function;

  ElementTarget({
    this.uris,
    this.method,
    this.inClass,
    this.className,
    this.field,
    this.variable,
    this.function,
  });

  static ElementTarget fromYaml(YamlMap yaml) {
    return ElementTarget(
      uris: (yaml['uris'] as List<dynamic>?)?.cast<String>(),
      method: yaml['method'] as String?,
      inClass: yaml['inClass'] as String?,
      className: yaml['className'] as String?,
      field: yaml['field'] as String?,
      variable: yaml['variable'] as String?,
      function: yaml['function'] as String?,
    );
  }
}
