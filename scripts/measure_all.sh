#!/bin/bash
set -u
cd /tmp/refactor-eq-workdir/cleanroom/24437
for pr in 24437 24483 24489 24623 25101; do
  SNAP=/tmp/refactor-eq-workdir/snapshots/$pr
  echo "=== PR $pr ==="
  # scope = TS files present in c_test OR c_llm (relative paths)
  (cd "$SNAP" && find c_test c_llm -type f \( -name '*.ts' -o -name '*.tsx' \) -not -name '*.test.*' 2>/dev/null) | sed 's|^[^/]*/||' | sort -u > /tmp/pr$pr-scope.txt
  echo "  scope: $(wc -l < /tmp/pr$pr-scope.txt) files"
  for snap in c_test c_llm c_final; do
    : > /tmp/pr$pr-$snap-files.txt
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      if [ -f "$SNAP/$snap/$f" ]; then
        echo "$SNAP/$snap/$f" >> /tmp/pr$pr-$snap-files.txt
      fi
    done < /tmp/pr$pr-scope.txt
    FC=$(wc -l < /tmp/pr$pr-$snap-files.txt | tr -d ' ')
    node measure_complexity.mjs $(cat /tmp/pr$pr-$snap-files.txt) > /tmp/pr$pr-$snap.json 2>/dev/null
    python3 -c "
import json
data = json.load(open('/tmp/pr$pr-$snap.json'))
n = sum(f['functionCount'] for f in data)
loc = sum(f['totalLoc'] for f in data)
mcc = sum(f['meanCyclomatic']*f['functionCount'] for f in data) / max(n,1)
maxCC = max((f['maxCyclomatic'] for f in data), default=0)
mcog = sum(f['meanCognitive']*f['functionCount'] for f in data) / max(n,1)
maxCog = max((f['maxCognitive'] for f in data), default=0)
maxNest = max((f['maxNesting'] for f in data), default=0)
print(f'  $snap (${FC}f): funcs={n} loc={loc} meanCC={mcc:.2f} maxCC={maxCC} meanCog={mcog:.2f} maxCog={maxCog} maxNest={maxNest}')
"
  done
done
