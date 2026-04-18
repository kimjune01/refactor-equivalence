## Build/test failure — round 5
```
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 594ms
   ✓ GeminiCliAgent Integration > resumes a session  529ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  00:42:10
   Duration  2.28s (transform 731ms, setup 0ms, collect 5.92s, tests 825ms, environment 0ms, prepare 269ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 12ms
 ✓ src/extension.test.ts (11 tests) 20ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 51ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  00:42:13
   Duration  1.69s (transform 708ms, setup 0ms, collect 2.94s, tests 83ms, environment 0ms, prepare 136ms)

```
