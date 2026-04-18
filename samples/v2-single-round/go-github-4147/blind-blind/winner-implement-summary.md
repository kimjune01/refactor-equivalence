Applied claims: C1, C2, C3, C4, C5.

Modified files:
- github/authorizations.go
- github/scim.go
- example/commitpr/main.go
- .custom-gcl.yml
- .golangci.yml
- tools/redundantptr/go.mod
- tools/redundantptr/redundantptr.go

Summary:
- Versioned the accepted OAuth and SCIM REST docs links with apiVersion=2022-11-28.
- Reverted the unrelated TreeEntry Path pointer rewrite from github.Ptr(file) to &file.
- Restored redundantptr linter configuration and its buildable module source, excluding test fixtures.
