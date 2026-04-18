# PR #24544 — feat(memory): add /memory inbox command for reviewing extracted skills

## PR body

## Summary

Add `/memory inbox` command that surfaces skills extracted by the background memory service, giving users a way to review, accept, or dismiss them through an interactive UI.

Previously, extracted skills landed in a temp directory with no user-facing visibility. Now users get:
- A one-time notification when new skills are extracted
- An interactive dialog (`/memory inbox`) to browse and act on them

## Details

**Core functions** (`packages/core/src/commands/memory.ts`):
- `listInboxSkills()` — scans the extraction inbox, loads SKILL.md frontmatter, cross-references extraction dates
- `moveInboxSkill()` — copies skill to global (`~/.gemini/skills`) or project (`.gemini/skills`) directory, then removes from inbox
- `dismissInboxSkill()` — deletes a skill from the inbox

**Interactive dialog** (`packages/cli/src/ui/components/SkillInboxDialog.tsx`):
- Two-phase `BaseSelectionList` UI: select a skill → choose destination (Global / Project / Dismiss)
- Esc navigates back between phases or closes the dialog
- After moving a skill, triggers `config.reloadSkills()` so it's immediately discoverable

**Notification** (`packages/core/src/services/memoryService.ts`):
- Emits `coreEvents.emitFeedback('info', ...)` when new skills are created during extraction
- Only fires when `skillsCreated.length > 0` — naturally non-repeating since extraction state tracks processed sessions

**ACP parity** (`packages/cli/src/acp/commands/memory.ts`):
- `InboxMemoryCommand` provides text-only listing for non-interactive contexts

## Related Issues

Closes #18007

## How to Validate

1. Run `/memory inbox` — should show "No extracted skills in inbox." if no skills have been extracted
2. To test with skills: manually create a directory under `~/.gemini/tmp/<project-hash>/memory/skills/<skill-name>/SKILL.md` with valid frontmatter
3. Run `/memory inbox` again — should show the skill in a selectable list
4. Select a skill → choose Global/Project/Dismiss → verify the skill moves to the correct directory
5. Verify Esc goes back (phase 2→1) or closes (phase 1→exit)

## Pre-Merge Checklist

- [ ] Updated relevant documentation and README (if needed)
- [ ] Noted breaking changes (if any)
- [ ] Validated on required platforms/methods:
  - [ ] MacOS
    - [ ] npm run
    - [ ] npx
    - [ ] Docker
    - [ ] Podman
    - [ ] Seatbelt
  - [ ] Windows
    - [ ] npm run
    - [ ] npx
    - [ ] Docker
  - [ ] Linux
    - [ ] npm run
    - [ ] npx
    - [ ] Docker


## Linked issues

### #18007 — Make the world a better place

Placeholder issue for all the places that require a issue

