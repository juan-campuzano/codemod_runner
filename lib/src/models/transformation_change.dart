import 'package:yaml/yaml.dart';

class TransformationChange {
  final ChangeKind kind;
  final String? newName;
  final String? newCode;
  final String? annotation;
  final String? parameter;
  final String? parameterName;
  final String? wrapperMethod;

  TransformationChange({
    required this.kind,
    this.newName,
    this.newCode,
    this.annotation,
    this.parameter,
    this.parameterName,
    this.wrapperMethod,
  });

  static TransformationChange fromYaml(YamlMap yaml) {
    return TransformationChange(
      kind: ChangeKind.fromString(yaml['kind'] as String),
      newName: yaml['newName'] as String?,
      newCode: yaml['newCode'] as String?,
      annotation: yaml['annotation'] as String?,
      parameter: yaml['parameter'] as String?,
      parameterName: yaml['parameterName'] as String?,
      wrapperMethod: yaml['wrapperMethod'] as String?,
    );
  }
}

enum ChangeKind {
  rename,
  replace,
  addAnnotation,
  removeAnnotation,
  addParameter,
  removeParameter,
  wrapInMethod,
  delete;

  static ChangeKind fromString(String str) {
    switch (str) {
      case 'rename':
        return ChangeKind.rename;
      case 'replace':
        return ChangeKind.replace;
      case 'addAnnotation':
        return ChangeKind.addAnnotation;
      case 'removeAnnotation':
        return ChangeKind.removeAnnotation;
      case 'addParameter':
        return ChangeKind.addParameter;
      case 'removeParameter':
        return ChangeKind.removeParameter;
      case 'wrapInMethod':
        return ChangeKind.wrapInMethod;
      case 'delete':
        return ChangeKind.delete;
      default:
        throw ArgumentError('Unknown change kind: $str');
    }
  }
}
