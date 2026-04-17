# PR #1285 — Optionally include reachable fieldpaths in prompt

## PR body

- Add support for expanding the set of reachable fields from top level variables in the prompt template.
  Fields are described in terms of CEL types including documentation where available. 

- Add a bazel rule to generate a file descriptor set from a proto_library that preserves source info.
  This is used to extract comments for formatting CEL environment descriptions.
