import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:codemod/codemod.dart';

import '../models/transformation_change.dart';
import '../models/transformation_rule.dart';

class JsonRulesSuggestor extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  final List<TransformationRule> rules;

  JsonRulesSuggestor(this.rules);

  static Future<JsonRulesSuggestor> fromFile(String jsonFilePath) async {
    final file = File(jsonFilePath);
    final content = await file.readAsString();
    final json = jsonDecode(content);

    final rules = <TransformationRule>[];
    final transforms = json['transforms'] as List<dynamic>;

    for (final transform in transforms) {
      final rule = TransformationRule.fromJson(transform);
      rules.add(rule);
    }

    return JsonRulesSuggestor(rules);
  }

  @override
  bool shouldResolveAst(FileContext context) => true;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);

    for (final rule in rules) {
      if (_instanceCreationMatches(node, rule)) {
        _applyChanges(node, rule);
      }
    }
  }

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

  bool _instanceCreationMatches(
      InstanceCreationExpression node, TransformationRule rule) {
    final target = rule.element;

    if (target.className != null) {
      final constructorName = node.constructorName;
      final typeName = constructorName.type.name2.lexeme;
      if (typeName != target.className) {
        return false;
      }
    }

    if (target.uris != null && target.uris!.isNotEmpty) {
      if (!target.uris!.any((targetUri) => context.path.endsWith(targetUri))) {
        return false;
      }
    }

    // // Verificar constructor específico (opcional)
    // if (target.constructor != null) {
    //   final constructorName = node.constructorName.name?.name;
    //   if (constructorName != target.constructor) {
    //     return false;
    //   }
    // }

    return true;
  }

  bool _methodMatches(
      MethodInvocation node, MethodElement element, TransformationRule rule) {
    final target = rule.element;

    if (target.method == null) {
      return false;
    }

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

    if (target.method == null) {
      return false;
    }

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

    if (target.className == null) {
      return false;
    }

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

    if (target.field == null) {
      return false;
    }

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
    } else if (node is ConstructorName) {
      yieldPatch(change.newName!, node.name!.offset, node.name!.end);
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

    // if (node is MethodDeclaration) {
    //   final args = node.parameters;
    //   final insertPosition = args!.rightParenthesis.offset;
    //   final prefix = args.parameters.isEmpty ? '' : ', ';
    //   yieldPatch('$prefix${change.parameter!}', insertPosition, insertPosition);
    // }

    if (node is MethodInvocation) {
      final args = node.argumentList;
      final insertPosition = args.rightParenthesis.offset;
      final prefix = args.arguments.isEmpty ? '' : ', ';
      yieldPatch('$prefix${change.parameter!}', insertPosition, insertPosition);
    } else if (node is InstanceCreationExpression) {
      final args = node.argumentList;
      final arguments = args.arguments;

      if (arguments.isEmpty) {
        final insertPosition = args.leftParenthesis.end;
        yieldPatch(change.parameter!, insertPosition, insertPosition);
      } else {
        // Need to format the parameter correctly from 'title: value' to 'title'
        final parameterParts = change.parameter!.split(':');

        // Need to verify that the parameter doesnt already exist
        for (final arg in arguments) {
          if (arg is NamedExpression &&
              arg.name.label.name == parameterParts.first) {
            return;
          }
        }
        final lastArg = arguments.last;
        final insertPosition = lastArg.end;
        yieldPatch(', ${change.parameter!}', insertPosition, insertPosition);
      }
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
