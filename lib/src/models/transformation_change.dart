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

  static TransformationChange fromJson(Map<String, dynamic> json) {
    return TransformationChange(
      kind: ChangeKind.fromString(json['kind'] as String),
      newName: json['newName'] as String?,
      newCode: json['newCode'] as String?,
      annotation: json['annotation'] as String?,
      parameter: json['parameter'] as String?,
      parameterName: json['parameterName'] as String?,
      wrapperMethod: json['wrapperMethod'] as String?,
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
