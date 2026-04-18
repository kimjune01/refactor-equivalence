## Accepted Claims

Empty Accepted Claims. The artifact already expresses the goal directly within the allowed production edit set: runtime users import the new internal `authchallenge` fork, the obsolete `docker/distribution` module and vendor entries are removed, and the old Manager code is no longer present in production source.

## Rejected

- Move `pkg/v1/remote/internal/authchallenge/manager_test.go` helper code into a more compact test utility: out of scope because the allowed edit set does not include test files, and the task forbids proposing edits to test files.
- Update `images/*` and `images/dot/*` references to `github.com/docker/distribution`: out of scope because those generated documentation assets are not in `allowed-files.txt`, and changing them would not be a bounded source refactor.
- Rename or unexport `authchallenge.Challenge` and `authchallenge.ResponseChallenges`: rejected because both are the package boundary used by `pkg/v1/remote/transport/bearer.go` and `pkg/v1/remote/transport/ping.go`; changing that API would add churn without making the fork more directly express the goal.
- Replace `parseAuthHeader`'s `header[http.CanonicalHeaderKey("WWW-Authenticate")]` lookup with a literal key or `Header.Values`: rejected as cosmetic; it does not remove accidental complexity tied to the fork, dependency removal, or test-only Manager separation.
- Rework `pickFromMultipleChallenges` in `pkg/v1/remote/transport/ping.go` while touching the import site: rejected because the helper logic predates the import swap and changing its selection structure is unrelated to forking the auth-challenge parser.
