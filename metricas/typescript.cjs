const { readdirSync, readFileSync } = require('node:fs');
const { resolve, relative, dirname } = require('node:path');
const { createHash } = require('node:crypto');

const root = resolve(process.argv[2]);
const ts = require(require.resolve('typescript', { paths: [resolve(root, 'backend')] }));
const base = resolve(root, 'backend/src');
const paths = readdirSync(base, { recursive: true })
  .filter(file => file.endsWith('.ts') && !file.endsWith('.d.ts'))
  .map(file => resolve(base, file)).sort();
const fileSet = new Set(paths);
const kinds = ts.SyntaxKind;
const branchKinds = new Set([
  kinds.IfStatement, kinds.ForStatement, kinds.ForInStatement, kinds.ForOfStatement,
  kinds.WhileStatement, kinds.DoStatement, kinds.CaseClause, kinds.CatchClause,
  kinds.ConditionalExpression,
]);
const operators = new Set([kinds.AmpersandAmpersandToken, kinds.BarBarToken, kinds.QuestionQuestionToken]);

function label(node, source) {
  if (node.name) return node.name.getText(source);
  if (ts.isConstructorDeclaration(node)) return 'constructor';
  if (ts.isVariableDeclaration(node.parent) || ts.isPropertyAssignment(node.parent)) {
    return node.parent.name.getText(source);
  }
  const call = node.parent;
  if (ts.isCallExpression(call)) {
    const route = call.arguments[0];
    const suffix = route && ts.isStringLiteral(route) ? ' ' + route.text : '';
    return call.expression.getText(source) + suffix;
  }
  return '<anónima>';
}

function measure(path) {
  const bytes = readFileSync(path);
  const source = ts.createSourceFile(path, bytes.toString('utf8'), ts.ScriptTarget.Latest, true);
  if (source.parseDiagnostics.length) throw new Error('Error de sintaxis en ' + path);
  const line = offset => source.getLineAndCharacterOfPosition(offset).line + 1;
  const code = new Set();
  const imports = new Set();
  const units = [];

  function addTokens(node) {
    if (node.kind >= kinds.FirstJSDocNode && node.kind <= kinds.LastJSDocNode) return;
    if (node.kind >= kinds.FirstToken && node.kind <= kinds.LastToken) {
      const start = node.getStart(source);
      if (node.end > start) {
        for (let n = line(start); n <= line(node.end - 1); n++) code.add(n);
      }
      return;
    }
    for (const child of node.getChildren(source)) addTokens(child);
  }
  addTokens(source);
  for (const node of source.statements) {
    if (!ts.isImportDeclaration(node) && !ts.isExportDeclaration(node)) continue;
    const specifier = node.moduleSpecifier;
    if (!specifier || !ts.isStringLiteral(specifier) || !specifier.text.startsWith('.')) continue;
    const target = resolve(dirname(path), specifier.text);
    const found = [target, target + '.ts', resolve(target, 'index.ts')].find(p => fileSet.has(p));
    if (found && found !== path) imports.add(relative(root, found).replaceAll('\\', '/'));
  }

  function visit(node, owner) {
    let current = owner;
    if (ts.isFunctionLike(node) && node.body) {
      const start = line(node.getStart(source));
      const end = line(node.end - 1);
      current = { name: label(node, source), line: start, loc: 0, cc: 1 };
      for (let n = start; n <= end; n++) current.loc += Number(code.has(n));
      units.push(current);
    }
    const decision = branchKinds.has(node.kind)
      || (ts.isBinaryExpression(node) && operators.has(node.operatorToken.kind));
    if (current && decision) current.cc++;
    ts.forEachChild(node, child => visit(child, current));
  }
  visit(source);
  return {
    file: relative(root, path).replaceAll('\\', '/'),
    sha256: createHash('sha256').update(bytes).digest('hex'),
    loc: code.size, imports: [...imports].sort(), units,
  };
}

process.stdout.write(JSON.stringify({ tool: 'TypeScript ' + ts.version, files: paths.map(measure) }));
