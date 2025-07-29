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

  static ElementTarget fromJson(Map<String, dynamic> json) {
    return ElementTarget(
      uris: (json['uris'] as List<dynamic>?)?.cast<String>(),
      method: json['method'] as String?,
      inClass: json['inClass'] as String?,
      className: json['className'] as String?,
      field: json['field'] as String?,
      variable: json['variable'] as String?,
      function: json['function'] as String?,
    );
  }
}
