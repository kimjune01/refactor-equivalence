## Build/test failure — round 1
```
stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/sdk/.geminiignore, continue without it.

stdout | src/agent.integration.test.ts > GeminiCliAgent Integration > propagates errors from dynamic instructions
Ignore file not found: /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/sdk/.geminiignore, continue without it.

 ✓ src/agent.integration.test.ts (5 tests) 593ms
   ✓ GeminiCliAgent Integration > resumes a session  530ms

 Test Files  4 passed (4)
      Tests  16 passed (16)
   Start at  00:14:37
   Duration  2.22s (transform 706ms, setup 0ms, collect 5.74s, tests 823ms, environment 0ms, prepare 255ms)


> gemini-cli-vscode-ide-companion@0.36.0-nightly.20260317.2f90b4653 test
> vitest run --exclude **/sandboxManager.integration.test.ts


 RUN  v3.2.4 /private/tmp/refactor-eq-workdir/bb-merged-24476/packages/vscode-ide-companion

 ✓ src/open-files-manager.test.ts (17 tests) 13ms
 ✓ src/extension.test.ts (11 tests) 19ms
 ✓ src/ide-server.test.ts (13 tests | 1 skipped) 51ms

 Test Files  3 passed (3)
      Tests  40 passed | 1 skipped (41)
   Start at  00:14:39
   Duration  1.63s (transform 665ms, setup 0ms, collect 2.85s, tests 83ms, environment 0ms, prepare 145ms)

```
