import 'dart:io';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:codemod/codemod.dart';
import 'package:yaml/yaml.dart';

class YamlRulesSuggestor extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  final List<TransformationRule> rules;

  YamlRulesSuggestor(this.rules);

  static Future<YamlRulesSuggestor> fromFile(String yamlFilePath) async {
    final file = File(yamlFilePath);
    final content = await file.readAsString();
    final yaml = loadYaml(content);

    final rules = <TransformationRule>[];
    final transforms = yaml['transforms'] as List<dynamic>;

    for (final transform in transforms) {
      final rule = TransformationRule.fromYaml(transform);
      rules.add(rule);
    }

    return YamlRulesSuggestor(rules);
  }

  @override
  bool shouldResolveAst(FileContext context) => true;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final element = node.methodName.staticElement;
    if (element is! MethodElement) return;

    for (final rule in rules) {
      if (_methodMatches(node, element, rule)) {
        _applyChanges(node, rule);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);

    for (final rule in rules) {
      if (_methodDeclarationMatches(node, rule)) {
        _applyChanges(node, rule);
      }
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);

    for (final rule in rules) {
      if (_classMatches(node, rule)) {
        _applyChanges(node, rule);
      }
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);

    for (final rule in rules) {
      if (_identifierMatches(node, rule)) {
        _applyChanges(node, rule);
      }
    }
  }

  bool _methodMatches(
      MethodInvocation node, MethodElement element, TransformationRule rule) {
    final target = rule.element;

    if (target.method != null && element.name != target.method) {
      return false;
    }

    if (target.inClass != null) {
      final enclosingClass = element.enclosingElement;
      if (enclosingClass is! ClassElement ||
          enclosingClass.name != target.inClass) {
        return false;
      }
    }

    if (target.uris != null && target.uris!.isNotEmpty) {
      final library = element.library;
      final uri = library.source.uri.toString();
      if (!target.uris!.any((targetUri) => uri.endsWith(targetUri))) {
        return false;
      }
    }

    return true;
  }

  bool _methodDeclarationMatches(
      MethodDeclaration node, TransformationRule rule) {
    final target = rule.element;

    if (target.method != null && node.name.lexeme != target.method) {
      return false;
    }

    if (target.inClass != null) {
      final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classDeclaration?.name.lexeme != target.inClass) {
        return false;
      }
    }

    if (target.uris != null && target.uris!.isNotEmpty) {
      if (!target.uris!.any((targetUri) => context.path.endsWith(targetUri))) {
        return false;
      }
    }

    return true;
  }

  bool _classMatches(ClassDeclaration node, TransformationRule rule) {
    final target = rule.element;

    if (target.inClass != null && node.name.lexeme != target.inClass) {
      return false;
    }

    if (target.className != null && node.name.lexeme != target.className) {
      return false;
    }

    if (target.uris != null && target.uris!.isNotEmpty) {
      if (!target.uris!.any((targetUri) => context.path.endsWith(targetUri))) {
        return false;
      }
    }

    return true;
  }

  bool _identifierMatches(SimpleIdentifier node, TransformationRule rule) {
    final target = rule.element;

    if (target.field != null && node.name != target.field) {
      return false;
    }

    if (target.variable != null && node.name != target.variable) {
      return false;
    }

    if (target.uris != null && target.uris!.isNotEmpty) {
      if (!target.uris!.any((targetUri) => context.path.endsWith(targetUri))) {
        return false;
      }
    }

    return true;
  }

  void _applyChanges(AstNode node, TransformationRule rule) {
    for (final change in rule.changes) {
      switch (change.kind) {
        case ChangeKind.rename:
          _applyRename(node, change);
          break;
        case ChangeKind.replace:
          _applyReplace(node, change);
          break;
        case ChangeKind.addAnnotation:
          _applyAddAnnotation(node, change);
          break;
        case ChangeKind.removeAnnotation:
          _applyRemoveAnnotation(node, change);
          break;
        case ChangeKind.addParameter:
          _applyAddParameter(node, change);
          break;
        case ChangeKind.removeParameter:
          _applyRemoveParameter(node, change);
          break;
        case ChangeKind.wrapInMethod:
          _applyWrapInMethod(node, change);
          break;
        case ChangeKind.delete:
          _applyDelete(node, change);
          break;
      }
    }
  }

  void _applyRename(AstNode node, TransformationChange change) {
    if (change.newName == null) return;

    if (node is MethodInvocation) {
      yieldPatch(change.newName!, node.methodName.offset, node.methodName.end);
    } else if (node is MethodDeclaration) {
      yieldPatch(change.newName!, node.name.offset, node.name.end);
    } else if (node is ClassDeclaration) {
      yieldPatch(change.newName!, node.name.offset, node.name.end);
    } else if (node is SimpleIdentifier) {
      yieldPatch(change.newName!, node.offset, node.end);
    }
  }

  void _applyReplace(AstNode node, TransformationChange change) {
    if (change.newCode == null) return;
    yieldPatch(change.newCode!, node.offset, node.end);
  }

  void _applyAddAnnotation(AstNode node, TransformationChange change) {
    if (change.annotation == null) return;

    final source = context.sourceText;
    final lineStart = source.lastIndexOf('\n', node.offset) + 1;
    final currentLine = source.substring(lineStart, node.offset);
    final indentation = currentLine.replaceAll(RegExp(r'[^\s].*'), '');

    final annotation = '@${change.annotation!}\n$indentation';
    yieldPatch(annotation, node.offset, node.offset);
  }

  void _applyRemoveAnnotation(AstNode node, TransformationChange change) {
    if (change.annotation == null) return;

    if (node is AnnotatedNode) {
      for (final metadata in node.metadata) {
        if (metadata.name.name == change.annotation) {
          final start = metadata.offset;
          final end = metadata.end;
          yieldPatch('', start, end);
        }
      }
    }
  }

  void _applyAddParameter(AstNode node, TransformationChange change) {
    if (change.parameter == null) return;

    if (node is MethodInvocation) {
      final args = node.argumentList;
      final insertPosition = args.rightParenthesis.offset;
      final prefix = args.arguments.isEmpty ? '' : ', ';
      yieldPatch('$prefix${change.parameter!}', insertPosition, insertPosition);
    }
  }

  void _applyRemoveParameter(AstNode node, TransformationChange change) {
    if (change.parameterName == null) return;

    if (node is MethodInvocation) {
      final args = node.argumentList.arguments;
      for (int i = 0; i < args.length; i++) {
        final arg = args[i];
        if (arg is NamedExpression &&
            arg.name.label.name == change.parameterName) {
          final start = i > 0 ? args[i - 1].end : arg.offset;
          final end = i < args.length - 1 ? args[i + 1].offset : arg.end;
          yieldPatch('', start, end);
          break;
        }
      }
    }
  }

  void _applyWrapInMethod(AstNode node, TransformationChange change) {
    if (change.wrapperMethod == null) return;

    yieldPatch('${change.wrapperMethod!}(', node.offset, node.offset);
    yieldPatch(')', node.end, node.end);
  }

  void _applyDelete(AstNode node, TransformationChange change) {
    yieldPatch('', node.offset, node.end);
  }
}

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
