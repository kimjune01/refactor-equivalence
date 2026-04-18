# PR #4145

This PR adds `redundantptr` linter to detect `github.Ptr(x)` calls that can be replaced with simple `&x`.
