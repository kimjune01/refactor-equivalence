# PR #24557 — Add inline snapshots to mdtest

## PR body

## Summary

This PR adds support for inline snapshots to mdtests.

The design differs from what was discussed in https://github.com/astral-sh/ty/issues/195:

* There's no `cargo insta` integration because it's unclear to me how that would work. 
* Diagnostic snapshotting is selective. Diagnostics that should be snapshotted must be marked with a `# snapshot: <code?>` comment. I think this design is superior because:
  * The test fails if there's a `diagnostic` block without any `# snapshot:` comment (is now unused)
  * The test can automatically insert the `diagnostic` block if there's at least one `# snapshot:` comment
  * Unlike with external snapshots, it allows asserting a single diagnostic in an existing test case without snapshotting many unrelated diagnostics too.
* Each file has its own `diagnostic` block (favors proximity)

Future extension:

* Add a mode to capture all diagnostics if we see the need for it

~~I still need to cleanup this PR. The current version is entirely written by codex.~~

I rewrote the entire PR because codex's solution was more complex and had worse UX.

An integration into our mdtest Python thing should be trivial as it only requires setting an environment variable to update snapshots.

Closes https://github.com/astral-sh/ty/issues/195

## Test Plan

Verified that tests fail:

* If an inline snapshot is outdated
* If there's an unnecessary snapshot block
* If a snapshot block is missing
* If there's an unmatched `# snapshot` comment
* If there's an unnecessary `# snapshot` comment (multiple once for the same line)
* If a code block has more than one snapshot block
* That snapshot blocks are correctly updated when running with the environment variable set.

## Linked issues
(none)
