import 'package:yaml/yaml.dart';

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

  static TransformationRule fromYaml(YamlMap yaml) {
    return TransformationRule(
      title: yaml['title'] as String,
      date: yaml['date'] as String?,
      element: ElementTarget.fromYaml(yaml['element']),
      changes: (yaml['changes'] as List<dynamic>)
          .map((change) => TransformationChange.fromYaml(change))
          .toList(),
    );
  }
}
