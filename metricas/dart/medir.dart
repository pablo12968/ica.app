import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:crypto/crypto.dart';

const operators = {'&&', '||', '??'};

class MeasureVisitor extends GeneralizingAstVisitor<void> {
  final int Function(int) line;
  final Set<int> code;
  final units = <Map<String, Object>>[];
  Map<String, Object>? owner;

  MeasureVisitor(this.line, this.code);

  String? unitName(AstNode node) {
    if (node is MethodDeclaration && !node.isAbstract) {
      return node.name.lexeme;
    }
    if (node is ConstructorDeclaration && node.externalKeyword == null) {
      return node.name?.lexeme ?? 'constructor';
    }
    if (node is FunctionDeclaration && node.externalKeyword == null) {
      return node.name.lexeme;
    }
    if (node is FunctionExpression && node.parent is! FunctionDeclaration) {
      return '<anónima>';
    }
    return null;
  }

  bool isDecision(AstNode node) =>
      node is IfStatement || node is IfElement ||
      node is ForStatement || node is ForElement ||
      node is WhileStatement || node is DoStatement ||
      node is ConditionalExpression || node is CatchClause ||
      node is SwitchCase || node is SwitchPatternCase ||
      node is SwitchExpressionCase ||
      (node is BinaryExpression && operators.contains(node.operator.lexeme));

  @override
  void visitNode(AstNode node) {
    final previous = owner;
    final name = unitName(node);
    if (name != null) {
      final start = node is AnnotatedNode
          ? node.firstTokenAfterCommentAndMetadata
          : node.beginToken;
      final first = line(start.offset);
      final last = line(node.end - 1);
      var loc = 0;
      for (var index = first; index <= last; index++) {
        if (code.contains(index)) loc++;
      }
      final current = <String, Object>{
        'name': name, 'line': first, 'loc': loc, 'cc': 1,
      };
      units.add(current);
      owner = current;
    }
    final current = owner;
    if (current != null && isDecision(node)) {
      current['cc'] = (current['cc'] as int) + 1;
    }
    super.visitNode(node);
    owner = previous;
  }
}

void main(List<String> args) {
  final root = Directory(args.single).absolute.uri;
  final base = Directory.fromUri(root.resolve('frontend/lib/'));
  final files = base.listSync(recursive: true).whereType<File>()
      .where((file) => file.path.endsWith('.dart')).toList()
    ..sort((first, second) => first.path.compareTo(second.path));
  final known = files.map((file) => file.uri.normalizePath()).toSet();
  String relative(Uri uri) =>
      Uri.decodeComponent(uri.path.substring(root.path.length));

  final rows = files.map((file) {
    final bytes = file.readAsBytesSync();
    final parsed = parseString(content: utf8.decode(bytes), path: file.path);
    int line(int offset) => parsed.lineInfo.getLocation(offset).lineNumber;
    final code = <int>{};
    for (var token = parsed.unit.beginToken; !token.isEof; token = token.next!) {
      if (token.length == 0) continue;
      for (var n = line(token.offset); n <= line(token.end - 1); n++) {
        code.add(n);
      }
    }
    final imports = <String>{};
    for (final directive in parsed.unit.directives) {
      if (directive is! NamespaceDirective) continue;
      final specifier = directive.uri.stringValue;
      if (specifier == null) continue;
      final target = specifier.startsWith('package:frontend/')
          ? base.uri.resolve(specifier.substring('package:frontend/'.length))
          : file.uri.resolve(specifier);
      if (known.contains(target) && target != file.uri) imports.add(relative(target));
    }
    final visitor = MeasureVisitor(line, code);
    parsed.unit.accept(visitor);
    return {
      'file': relative(file.uri),
      'sha256': sha256.convert(bytes).toString(),
      'loc': code.length,
      'imports': imports.toList()..sort(),
      'units': visitor.units,
    };
  }).toList();
  stdout.write(jsonEncode({'tool': 'Dart analyzer 10.1.0', 'files': rows}));
}
