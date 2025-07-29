import 'element_target.dart';
import 'transformation_change.dart';

class TransformationRule {
  final String title;
  final String? date;
  final ElementTarget element;
  final List<TransformationChange> changes;

  TransformationRule({
    required this.title,
    this.date,
    required this.element,
    required this.changes,
  });

  static TransformationRule fromJson(Map<String, dynamic> json) {
    return TransformationRule(
      title: json['title'] as String,
      date: json['date'] as String?,
      element: ElementTarget.fromJson(json['element']),
      changes: (json['changes'] as List<dynamic>)
          .map((change) => TransformationChange.fromJson(change))
          .toList(),
    );
  }
}
