# PR #4147

Since there are two API versions (see #4077), GitHub API links redirect to the latest version by default. However, this library currently supports version `2022-11-28`, so we need to add `?apiVersion=2022-11-28` to every link.
