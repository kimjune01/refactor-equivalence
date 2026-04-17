# PR #4153

This PR refactors the behaviour of `DownloadContents` & `DownloadContentsWithMeta` with the former now being a direct passthrough to the latter as the only difference was the signature. The code has been refactored to use the API directly instead of via an unnecessary layer of indirection.

I've added an OpenAPI update to this PR as it proves that the updated code works against GitHub.

This change is required for #4151.
