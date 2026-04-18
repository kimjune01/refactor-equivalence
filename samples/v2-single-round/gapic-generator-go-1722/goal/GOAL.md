# PR #1722
This PR implements fallback heuristics to deduce resource name templates for unannotated legacy services (like Compute Engine).

It is gated behind a new DynamicResourceHeuristicsFeature flag.

The solution is a two-step process:

1. Scan standard CRUD methods in the API package to learn a vocabulary of valid collection nouns (e.g. projects, topics).
2. Process URI endpoints against the learned vocabulary to return validated paths as templates.

The learned vocabulary is stored as a new field on the Generator struct so it can be shared across file generation runs without redundant rescans. The implementation includes robust custom verb stripping (e.g. :cancel, :publish), correctly handles interstitial literals like "global", and discards partial matches if variables sitting to the left are not in the vocabulary.
