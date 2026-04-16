#!/usr/bin/env node
/**
 * Compute per-function complexity metrics for TypeScript files.
 * Uses @typescript-eslint/typescript-estree for parsing.
 *
 * Usage: node measure_complexity.mjs <file1.ts> [file2.ts ...]
 * Output: JSON array of per-function metrics + file-level aggregates.
 */

import { parse } from '@typescript-eslint/typescript-estree';
import { readFileSync } from 'fs';

function analyzeFile(filePath) {
  const code = readFileSync(filePath, 'utf-8');
  const ast = parse(code, {
    loc: true,
    range: true,
    jsx: true,
  });

  const functions = [];

  function walkForFunctions(node, parentName) {
    if (!node || typeof node !== 'object') return;

    let funcName = null;
    let isFuncNode = false;

    switch (node.type) {
      case 'FunctionDeclaration':
        funcName = node.id?.name || '<anonymous>';
        isFuncNode = true;
        break;
      case 'MethodDefinition':
        funcName = parentName
          ? `${parentName}.${node.key?.name || node.key?.value || '<computed>'}`
          : node.key?.name || node.key?.value || '<method>';
        // Walk into the value (FunctionExpression) but treat as this method
        if (node.value) {
          const metrics = computeMetrics(node.value);
          functions.push({
            name: funcName,
            line: node.loc.start.line,
            ...metrics,
          });
        }
        // Still walk children for nested functions
        for (const key of Object.keys(node)) {
          if (key === 'value') continue; // already processed
          const child = node[key];
          if (Array.isArray(child)) child.forEach(c => walkForFunctions(c, parentName));
          else if (child && typeof child === 'object' && child.type) walkForFunctions(child, parentName);
        }
        return;
      case 'FunctionExpression':
      case 'ArrowFunctionExpression':
        // Only count if assigned to a variable or property
        funcName = node.id?.name || '<arrow>';
        isFuncNode = true;
        break;
      case 'ClassDeclaration':
      case 'ClassExpression': {
        const className = node.id?.name || '<class>';
        for (const key of Object.keys(node)) {
          const child = node[key];
          if (Array.isArray(child)) child.forEach(c => walkForFunctions(c, className));
          else if (child && typeof child === 'object' && child.type) walkForFunctions(child, className);
        }
        return;
      }
    }

    if (isFuncNode) {
      const metrics = computeMetrics(node);
      functions.push({
        name: funcName,
        line: node.loc.start.line,
        ...metrics,
      });
    }

    for (const key of Object.keys(node)) {
      const child = node[key];
      if (Array.isArray(child)) child.forEach(c => walkForFunctions(c, parentName));
      else if (child && typeof child === 'object' && child.type) walkForFunctions(child, parentName);
    }
  }

  function computeMetrics(funcNode) {
    let cyclomatic = 1;
    let cognitive = 0;
    let maxNesting = 0;

    function walk(node, nestingLevel) {
      if (!node || typeof node !== 'object') return;

      const nestingIncrements = new Set([
        'IfStatement', 'ForStatement', 'ForInStatement', 'ForOfStatement',
        'WhileStatement', 'DoWhileStatement', 'SwitchStatement',
        'CatchClause', 'ConditionalExpression',
      ]);

      const cyclomaticIncrements = new Set([
        'IfStatement', 'ForStatement', 'ForInStatement', 'ForOfStatement',
        'WhileStatement', 'DoWhileStatement', 'CatchClause',
        'ConditionalExpression',
      ]);

      if (node.type === 'SwitchCase' && node.test !== null) {
        cyclomatic++;
      }

      if (cyclomaticIncrements.has(node.type)) {
        cyclomatic++;
      }

      if (node.type === 'LogicalExpression' && (node.operator === '&&' || node.operator === '||' || node.operator === '??')) {
        cyclomatic++;
        cognitive++;
      }

      let newNesting = nestingLevel;
      if (nestingIncrements.has(node.type)) {
        cognitive += 1 + nestingLevel;
        newNesting = nestingLevel + 1;
        if (newNesting > maxNesting) maxNesting = newNesting;
      }

      for (const key of Object.keys(node)) {
        if (key === 'type' || key === 'loc' || key === 'range' || key === 'parent') continue;
        const child = node[key];
        if (Array.isArray(child)) {
          child.forEach(c => {
            if (c && typeof c === 'object' && c.type) walk(c, newNesting);
          });
        } else if (child && typeof child === 'object' && child.type) {
          walk(child, newNesting);
        }
      }
    }

    walk(funcNode.body || funcNode, 0);

    const startLine = funcNode.loc.start.line;
    const endLine = funcNode.loc.end.line;
    const loc = endLine - startLine + 1;

    return { cyclomatic, cognitive, maxNesting, loc };
  }

  walkForFunctions(ast, null);

  const totalLoc = code.split('\n').length;
  const functionCount = functions.length;
  const meanCyclomatic = functionCount > 0
    ? functions.reduce((s, f) => s + f.cyclomatic, 0) / functionCount
    : 0;
  const maxCyclomatic = functionCount > 0
    ? Math.max(...functions.map(f => f.cyclomatic))
    : 0;
  const meanCognitive = functionCount > 0
    ? functions.reduce((s, f) => s + f.cognitive, 0) / functionCount
    : 0;
  const maxCognitive = functionCount > 0
    ? Math.max(...functions.map(f => f.cognitive))
    : 0;
  const maxNesting = functionCount > 0
    ? Math.max(...functions.map(f => f.maxNesting))
    : 0;

  return {
    file: filePath,
    totalLoc,
    functionCount,
    meanCyclomatic: +meanCyclomatic.toFixed(2),
    maxCyclomatic,
    meanCognitive: +meanCognitive.toFixed(2),
    maxCognitive,
    maxNesting,
    functions,
  };
}

const files = process.argv.slice(2);
if (files.length === 0) {
  console.error('Usage: node measure_complexity.mjs <file1.ts> [file2.ts ...]');
  process.exit(1);
}

const results = files.map(f => analyzeFile(f));
console.log(JSON.stringify(results, null, 2));
