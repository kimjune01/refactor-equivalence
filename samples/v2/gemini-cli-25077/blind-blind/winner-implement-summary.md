Applied claims: C1, C2, C3, C4

Modified files:
- packages/core/src/sandbox/windows/GeminiSandbox.cs
- packages/core/src/sandbox/windows/WindowsSandboxManager.ts

Summary:
- C1: Added a shared LowIntegritySid constant and used it for token lowering and bulk ACL SID creation.
- C2: Extracted low-integrity mandatory-label application into ApplyLowIntegrityLabel.
- C3: Split deny and allow per-path ACL mutations into ApplyDenyAcl and ApplyAllowAcl while keeping loop-level warning behavior.
- C4: Factored manifest creation in prepareCommand through a local writeManifest helper.
