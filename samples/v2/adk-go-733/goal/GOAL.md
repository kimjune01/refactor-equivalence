# PR #733

SkillToolset encapsulates the Agent Skills feature. This toolset ensures agent is equipped with all the tools needed to use skills and is provided with proper instructions.

What skill toolset enable agent to do:
- List available skills.
- Read instructions of the skills (by skill name).
- Read specific resources of the skills (by resource path).

Current implementation is very basic, e.g.:
- There is no script execution support yet.
- Skill activation is history-based: skill instructions and resources are provided to the llm as function call results in conversation history.
- Every resource should be specifically mentioned in the SKILL.md file: the agent is unable to list resources available for the skills.
