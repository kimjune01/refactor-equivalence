#!/usr/bin/env bash
# Compute per-file complexity metrics for Python files.
# Cyclomatic via radon, cognitive via cognitive_complexity package, LOC via file line count.
#
# Usage: measure_complexity_py.sh <file1.py> [file2.py ...]
# Output: JSON array of per-file metrics.
set -euo pipefail

if [ $# -eq 0 ]; then
  echo 'Usage: measure_complexity_py.sh <file.py> [file.py ...]' >&2
  exit 1
fi

python3 - "$@" <<'PYEOF'
import ast
import json
import sys

try:
    from cognitive_complexity.api import get_cognitive_complexity
except ImportError:
    get_cognitive_complexity = None


def cyclomatic(node):
    """Recursively count decision points within a function node."""
    count = 1  # base
    for sub in ast.walk(node):
        if isinstance(sub, (ast.If, ast.For, ast.While, ast.AsyncFor,
                             ast.ExceptHandler, ast.With, ast.AsyncWith)):
            count += 1
        elif isinstance(sub, ast.BoolOp):
            count += len(sub.values) - 1
        elif isinstance(sub, ast.IfExp):
            count += 1
        elif isinstance(sub, ast.comprehension):
            if sub.ifs:
                count += len(sub.ifs)
    return count


def max_nesting(node, current=0, best=0):
    best = max(best, current)
    if isinstance(node, (ast.If, ast.For, ast.While, ast.AsyncFor,
                          ast.Try, ast.With, ast.AsyncWith)):
        current += 1
        best = max(best, current)
    for child in ast.iter_child_nodes(node):
        best = max(best, max_nesting(child, current, best))
    return best


def analyze_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            source = f.read()
    except Exception as e:
        return {'file': path, 'error': str(e), 'functions': []}

    try:
        tree = ast.parse(source, filename=path)
    except Exception as e:
        return {'file': path, 'error': f'parse: {e}', 'functions': []}

    total_loc = len(source.splitlines())
    functions = []

    def walk(node, class_name=None):
        for child in ast.iter_child_nodes(node):
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                name = child.name if not class_name else f'{class_name}.{child.name}'
                cc = cyclomatic(child)
                cog = 0
                if get_cognitive_complexity:
                    try:
                        cog = get_cognitive_complexity(child)
                    except Exception:
                        cog = 0
                nest = 0
                for sub in child.body:
                    nest = max(nest, max_nesting(sub, 0, 0))
                loc = (child.end_lineno or child.lineno) - child.lineno + 1
                functions.append({
                    'name': name,
                    'line': child.lineno,
                    'cyclomatic': cc,
                    'cognitive': cog,
                    'maxNesting': nest,
                    'loc': loc,
                })
                walk(child, name)
            elif isinstance(child, ast.ClassDef):
                walk(child, child.name)
            else:
                walk(child, class_name)

    walk(tree)

    n = len(functions)
    mean_cc = sum(f['cyclomatic'] for f in functions) / max(n, 1)
    mean_cog = sum(f['cognitive'] for f in functions) / max(n, 1)
    max_cc = max((f['cyclomatic'] for f in functions), default=0)
    max_cog = max((f['cognitive'] for f in functions), default=0)
    max_nest = max((f['maxNesting'] for f in functions), default=0)

    return {
        'file': path,
        'totalLoc': total_loc,
        'functionCount': n,
        'meanCyclomatic': round(mean_cc, 2),
        'maxCyclomatic': max_cc,
        'meanCognitive': round(mean_cog, 2),
        'maxCognitive': max_cog,
        'maxNesting': max_nest,
        'functions': functions,
    }


results = [analyze_file(f) for f in sys.argv[1:]]
print(json.dumps(results, indent=2))
PYEOF
