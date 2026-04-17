# PR #2248

- alternative to https://github.com/google/go-containerregistry/pull/2247, but with the commits squashed, and authors added as co-author

----

### fork distribution client v3 auth-challenge as an internal package

This forks the distribution's registry client auth-challenge code v3.0.0;
https://github.com/distribution/distribution/commit/9ed95e7365224025ee89365e12cf128e1f1bf965

The client code has moved to an internal package in the distribution project,
and is used to handle `WWW-Authenticate` headers. It was written a long time
ago, and only handles RFC 2617 (superseded by RFC 9110). Possibly there's more
current implementations for this, but this would introduce new dependencies, so
we can keep the status quo for now, and fork this code as an internal package.

Keeping it internal, due to the known limitations mentioned above, and to avoid
it being used by others assuming it's a general-purpose implementation.

This is the result of the following steps:

```bash
# install filter-repo (https://github.com/newren/git-filter-repo/blob/main/INSTALL.md)
brew install git-filter-repo

# create a temporary clone of docker
cd ~/Projects
git clone https://github.com/distribution/distribution.git distribution_auth
cd distribution_auth

# switch to v3.0.0 (git-filter doesn't like multiple branches, so reset)
git reset --hard v3.0.0

# commit taken from
git rev-parse --verify HEAD
9ed95e7365224025ee89365e12cf128e1f1bf965

git filter-repo --analyze

# remove all code, except for 'internal/client/auth/challenge'
# rename to 'pkg/v1/remote/internal/authchallenge'
# include history of old location ('registry/client/auth/challenge')
git filter-repo \
  --force \
  --path 'internal/client/auth/challenge' \
  --path 'registry/client/auth/challenge' \
  --path-rename internal/client/auth/challenge:pkg/v1/remote/internal/authchallenge

# go to the target github.com/docker/docker repository
cd ~/go/src/github.com/google/go-containerregistry

# create a branch to work with
git checkout -b fork_registryclient_authchallenge

# add the temporary repository as an upstream and make sure it's up-to-date
git remote add distribution_auth ~/Projects/distribution_auth
git fetch distribution_auth

# merge the upstream code
git merge --allow-unrelated-histories --signoff -S distribution_auth/main
```

After adding the internal fork;

- authchallenge: rename package and update imports
- pkg/v1/remote/internal/authchallenge: make manager-code a test-util
  The Manager code is only used as part of tests; move it to _test files
  to have a clearer separation between "production" code and test-code.

