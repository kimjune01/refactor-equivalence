Applied claims:
- C1: Updated packages/core/src/policy/policies/plan.toml to allow plan-mode subagents via virtual tool names instead of an invoke_agent argsPattern.
- C2: Updated packages/core/src/agents/registry.ts to register dynamic remote-agent policy rules by agent name and removed the now-unused AgentTool import.

Modified files:
- packages/core/src/policy/policies/plan.toml
- packages/core/src/agents/registry.ts
