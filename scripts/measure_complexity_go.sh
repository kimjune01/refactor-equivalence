#!/usr/bin/env bash
# Compute per-file complexity metrics for Go files.
# Uses gocyclo (cyclomatic) + gocognit (cognitive).
#
# Usage: measure_complexity_go.sh <file1.go> [file2.go ...]
# Output: JSON {files: [...], total: {...}}
set -euo pipefail

if [ $# -eq 0 ]; then
  echo 'Usage: measure_complexity_go.sh <file.go> [file.go ...]' >&2
  exit 1
fi

# gocyclo outputs: `<cyclo> <package> <func> <file:line:col>` per function.
# gocognit outputs: `<cognit> <package> <func> <file:line:col>` per function.

# Run both over all files, one file at a time for correct scoping.
python3 - "$@" <<'PYEOF'
import json
import subprocess
import sys

def parse_tool_output(output):
    """Parse gocyclo / gocognit output into list of (score, qualified_func_name)."""
    results = []
    for line in output.strip().splitlines():
        parts = line.split(None, 3)
        if len(parts) < 4:
            continue
        try:
            score = int(parts[0])
        except ValueError:
            continue
        pkg = parts[1]
        func = parts[2]
        loc = parts[3]
        # Qualified: pkg.func@loc — use loc to disambiguate methods with same name
        results.append({
            "score": score,
            "package": pkg,
            "function": func,
            "location": loc,
        })
    return results

def file_loc(path):
    try:
        with open(path, 'r') as f:
            return len(f.read().splitlines())
    except Exception:
        return 0

files = sys.argv[1:]

# gocyclo and gocognit accept multiple files; run once each and parse results.
cyclo_output = subprocess.run(['gocyclo', '-over', '0'] + files, capture_output=True, text=True).stdout
cognit_output = subprocess.run(['gocognit', '-over', '0'] + files, capture_output=True, text=True).stdout

cyclo_results = parse_tool_output(cyclo_output)
cognit_results = parse_tool_output(cognit_output)

# Build per-file metrics
per_file = {}
for f in files:
    per_file[f] = {
        'file': f,
        'totalLoc': file_loc(f),
        'functions': [],
    }

def match_file(loc_str, files):
    loc_file = loc_str.split(':', 1)[0]
    for f in files:
        if f.endswith(loc_file) or loc_file.endswith(f) or f == loc_file:
            return f
    return None

# Pair cyclo + cognit by (package, function, location)
cog_map = {
    (r['package'], r['function'], r['location']): r['score']
    for r in cognit_results
}

for c in cyclo_results:
    key = (c['package'], c['function'], c['location'])
    cognit = cog_map.get(key, 0)
    fmatch = match_file(c['location'], files)
    if not fmatch:
        continue
    per_file[fmatch]['functions'].append({
        'name': c['function'],
        'package': c['package'],
        'location': c['location'],
        'cyclomatic': c['score'],
        'cognitive': cognit,
    })

# Per-file aggregates
file_list = []
for f in files:
    fe = per_file[f]
    funcs = fe['functions']
    n = len(funcs)
    cc_mean = sum(x['cyclomatic'] for x in funcs) / max(n, 1)
    cog_mean = sum(x['cognitive'] for x in funcs) / max(n, 1)
    cc_max = max((x['cyclomatic'] for x in funcs), default=0)
    cog_max = max((x['cognitive'] for x in funcs), default=0)
    file_list.append({
        'file': f,
        'totalLoc': fe['totalLoc'],
        'functionCount': n,
        'meanCyclomatic': round(cc_mean, 2),
        'maxCyclomatic': cc_max,
        'meanCognitive': round(cog_mean, 2),
        'maxCognitive': cog_max,
        'functions': funcs,
    })

print(json.dumps(file_list, indent=2))
PYEOF
