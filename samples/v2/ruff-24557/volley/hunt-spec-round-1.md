## Finding F1 — Duplicate trim claim overstates snapshot parsing involvement
**Severity**: warning
**Claim**: C1
**What**: The claim's goal link says removing the duplicate trim clarifies the shared parsing path for `# snapshot`, `# error:`, and `# revealed:` pragmas, but the duplicated `keyword.trim()` is only inside `UnparsedAssertion::from_comment`, which handles assertion comments after `# snapshot` has already been recognized separately. This does not make the code change unsafe, but it misstates which parser path is being simplified.
**Evidence**: `crates/ty_test/src/pragma_comments.rs:237` checks `comment == "snapshot"` and returns `UnparsedPragmaComment::Snapshot` before calling `UnparsedAssertion::from_comment` at `crates/ty_test/src/pragma_comments.rs:242`; the duplicate trim is in `UnparsedAssertion::from_comment` at `crates/ty_test/src/pragma_comments.rs:275` and `crates/ty_test/src/pragma_comments.rs:277`.
**Fix**: Narrow the goal link/justification to assertion pragma parsing (`# error:` and `# revealed:`), or state that this is cleanup within the broader pragma parser file rather than the `# snapshot` parse branch itself.

## Finding F2 — New inline snapshot parse error is underspecified and appears unreachable
**Severity**: warning
**Claim**: C4
**What**: The claim requires replacing `file.code_blocks.last_mut().unwrap()` with a `bail!(...)` branch, but it only describes the error semantically instead of specifying the exact user-visible string. Parser tests in this crate commonly assert exact `err.to_string()` values, so leaving the wording to the implementer creates avoidable guesswork. Also, current construction appears to guarantee that every `EmbeddedFile` has at least one `CodeBlock`, so the proposed branch may be dead validation rather than a meaningful mdtest edge.
**Evidence**: `crates/ty_test/src/parser.rs:859` creates each new `EmbeddedFile` with `code_blocks: vec![CodeBlock { ... }]`; later blocks call `append_code` at `crates/ty_test/src/parser.rs:888`, which can skip empty blocks but does not remove the initial code block. Existing parser tests assert exact parse error strings, for example `crates/ty_test/src/parser.rs:1613`, `crates/ty_test/src/parser.rs:1670`, and `crates/ty_test/src/parser.rs:2140`.
**Fix**: Specify the exact `bail!` message if the claim is kept, and clarify the reachable malformed input it is meant to handle; otherwise reject the claim as unnecessary dead-edge cleanup.
