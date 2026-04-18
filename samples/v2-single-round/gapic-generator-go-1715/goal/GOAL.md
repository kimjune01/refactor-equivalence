# PR #1715
Upgrades Bazel dependencies to fully support the Go 1.25.0 requirement introduced by x/sync in #1702 

Updates:
- `io_bazel_rules_go` to `v0.60.0`
- `bazel_gazelle` to `v0.47.0`
- `rules_proto` to `7.1.0`
- `com_google_protobuf` to `v31.0`
- Added `rules_python` 1.9.0, `rules_java` 9.6.1, `bazel_features` 1.30.0 for protobuf v31.0 compatibility
- Updated minimum Bazel version to `6.5.0` via `.bazelversion`
- Updated C++ standard to `c++17` in `.bazelrc`
- Fixed Linux sed syntax in Makefile for update-bazel-repos

Testing Steps Taken:
1. Ran `bazelisk clean --expunge` to test a clean build.
2. Verified Gazelle with `make update-bazel-repos` to ensure BUILD file generation remains intact.
3. Compiled and ran full integration tests against the mock Showcase server using `make test`.
4. Verified compilation across all 5 test suites under optimized build mode `bazelisk test //... -c opt`.
