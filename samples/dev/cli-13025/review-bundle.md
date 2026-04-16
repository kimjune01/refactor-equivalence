# Blind merge-readiness review — cli/cli PR 13025

## PR metadata

**Title:** Consolidate actor-mode signals into ApiActorsSupported

**Body:**

## Description

So the diff here is gnarly but bear with me :sweat_smile:. In #13009 I was frustrated seeing the divergence between how actor types were handled for assignees vs reviewers (this is my fault I'm sure).

Now, with all the context, I recognize that these two paths for handling actor types are not actually different. They're keying on the same feature detector field (`ActorIsAssignable`) anyway, but they ended up diverging and checking different things across the stack:

### The divergence

There are two flows: **create** (`pr create`, `issue create`) uses `IssueMetadataState`, and **edit** (`pr edit`, `issue edit`) uses `Editable`. The actor signal was carried differently in each, and assignees vs reviewers were handled asymmetrically:

**Create flows** (via `IssueMetadataState`):

| Layer | Assignees | Reviewers |
|-------|-----------|-----------|
| State struct | `ActorAssignees` field | `ActorReviewers` field (separate, always same value) |
| `MetadataSurvey` | Explicit `state.ActorAssignees` checks | Only checked `reviewerSearchFunc != nil` |
| `params.go` mutation | `tb.ActorAssignees` for login vs ID | `tb.ActorReviewers` for login vs ID |

**Edit flows** (via `Editable`):

| Layer | Assignees | Reviewers |
|-------|-----------|-----------|
| Editable struct | `EditableAssignees.ActorAssignees` | Nothing, no equivalent |
| `RepoMetadataInput` | `ActorAssignees` field | Nothing |
| `RepoMetadata` fetch | Branched on `ActorAssignees` for actor-aware fetch | No reviewer-specific branch |
| `FetchOptions` | Skipped fetch when `ActorAssignees` true | No equivalent optimization |
| Reviewer mutations | Piggybacked on `editable.Assignees.ActorAssignees`[^1] | No own field to check |

[^1]: Particularly confusing: the reviewer mutation decision in `pr edit` was keyed off the *assignee* actor flag because reviewers didn't carry their own. See the [write-up on #13009](https://github.com/cli/cli/pull/13009#issuecomment-4122700998) for the full investigation.

**Shared** (used by both flows):

| Layer | Assignees | Reviewers |
|-------|-----------|-----------|
| Feature detection | `issueFeatures.ActorIsAssignable` | Same (single source of truth) |

So the source was always one signal, but it fanned out into different field names on different structs, with reviewers missing coverage in the edit path entirely.

After this PR, it's just one field at every level:

| Layer | Assignees & Reviewers |
|-------|-----------------------|
| Feature detection | `issueFeatures.ApiActorsSupported` |
| `IssueMetadataState` (create) | `state.ApiActorsSupported` |
| `Editable` (edit) | `editable.ApiActorsSupported` |
| `RepoMetadataInput` | `input.ApiActorsSupported` |
| `MetadataSurvey` | `state.ApiActorsSupported` |
| `params.go` mutation | `tb.ApiActorsSupported` |
| `pr edit` reviewer mutations | `editable.ApiActorsSupported` |


### What this PR does

This PR calls it like it is: these are all the same capability signal. 

1. It consolidates `ActorAssignees` and `ActorReviewers` into a single `ApiActorsSupported` field that lives at the shared level on each struct (`Editable`, `IssueMetadataState`, `RepoMetadataInput`). Both assignees and reviewers key off the same signal.
2. The feature detector field is also renamed from `ActorIsAssignable` to `ApiActorsSupported` so the name is consistent from detection through to consumption.
3. BONUS: I also expanded the documentation on the feature detector to describe exactly when this codepath can be consolidated and what GraphQL schema additions to look for to confirm GHES support is ready. Previously the feature detector was multi-purposed and the documentation didn't reflect the breadth of what it affects.

Every branch site in the code is now tagged with `// TODO ApiActorsSupported` so a future cleanup can be done with a single grep.

### Why one field and not separate feature detectors?

You may be wondering: these seem like somewhat different features (actor assignees vs actor reviewers vs search-based selection), so why not have separate feature detector fields?

In short, I believe it is simpler to group them. The harm is that, sure, maybe Copilot coding agent could hypothetically be allowed on GHES sooner than Copilot code reviewer or the other login-based mutations. But the complexity would matrix really quickly IMO, and the juice isn't worth the squeeze.

So: group all the actor stuff together, control it with one field. The state is easier to reason about and we can ship GHES support with more confidence because we know these things are compatible.

## Acceptance & Regression Testing

**38 scenarios tested** across github.com and GHES 3.20, all passing: [Acceptance test results](https://gist.github.com/BagToad/4798ace48cf721b0ff35e4df21e73f83)

## Notes For Reviewers

Commits are intentionally grouped. Some are chunky, but thematic, and IMO it's easier to review this way.

### Commits

1. [`3c00ffd`](https://github.com/cli/cli/commit/3c00ffdade319d47505479edf215909762d46bac) — **Core change: Consolidate actor signals** into `ApiActorsSupported` on `Editable`, `IssueMetadataState`, `RepoMetadataInput`
2. [`ae5e857`](https://github.com/cli/cli/commit/ae5e857c2e4c23be065667b4515de9c82588035f) — **Rename feature detector** from `ActorIsAssignable` to `ApiActorsSupported`
3. [`92f205e`](https://github.com/cli/cli/commit/92f205e54bca14d70d428fd7e5fd2f4fe596d57c) — **Document GHES removal criteria** on the feature detector struct
4. [`6a68ebc`](https://github.com/cli/cli/commit/6a68ebc1c9e49cfb0760be7fd7d987fb582c455d) — **Nit: simplify redundant expression** in survey.go where `RepoMetadataInput.ApiActorsSupported` was rechecking conditions already gated upstream
5. [`bff468b`](https://github.com/cli/cli/commit/bff468bafe1d7144d23aaf7ff25191361f16f9e2) — **Fix: wire up `@copilot` assignee replacement** in `pr create` and add `[bot]` suffix for `replaceActorsForAssignable` mutation (bugs introduced in #13009)
6. [`391e661`](https://github.com/cli/cli/commit/391e6616d5abb75cc4d148bb671b15c2f4f28c70) — **Fix: use `useReviewerSearch` consistently** in the reviewer prompt path (matched existing assignee pattern)

## Task

Two candidate Go implementations. Phase 1: forced choice. Phase 2: trajectory after seeing C_final. Phase 3: blinding check.

## Phase 1
- Candidate A: `diff-A.patch`
- Candidate B: `diff-B.patch`

Assuming tests pass, which version to approve for merge? A or B. Rationale 1–2 sentences. Note semantic concerns.

## Phase 2
See `diff-C_final.patch`. Classify A and B as past/short/wrong relative to C_final.

## Phase 3
Did you identify any candidate as final/LLM/identifiable?

## Output JSON
{
  "phase_1_choice": "A" | "B",
  "phase_1_rationale": "...",
  "phase_1_semantic_concerns": { "A": "..." or null, "B": "..." or null },
  "phase_2_trajectory_A": "past" | "short" | "wrong",
  "phase_2_trajectory_B": "past" | "short" | "wrong",
  "phase_3_blinding": {
    "believed_a_final": bool, "believed_b_final": bool,
    "believed_a_llm": bool, "believed_b_llm": bool,
    "identifying_signals": "..." or null
  }
}
