## Build: PASS
## Tests: PASS

## Finding F1 — Score is still missing the required experimental warning
**Severity**: warning
**File**: firestore/pipeline_function.go:1014
**What**: The accepted claim C1 requires `Score` to carry the same two-line Firestore Pipelines experimental warning used by `DocumentMatches` and `GeoDistance`, because the goal explicitly lists `Score` among features that must retain/restore the Public Preview warning. The current doc comment reaches the example and then immediately declares the function, so the warning was not applied:

```go
  1005	// Score creates an expression that evaluates to the search score that reflects the topicality of the document to all of the text
  1006	// predicates (for example: DocumentMatches) in the search query.
  1007	//
  1008	// This Expression can only be used within a Search stage.
  1009	//
  1010	// Example:
  1011	//
  1012	//	client.Pipeline().Collection("restaurants").
  1013	//		Search(WithSearchQuery("waffles"), WithSearchSort(Descending(Score())))
  1014	func Score() Expression {
  1015		return newBaseFunction("score", nil)
  1016	}
```

**Fix**: Add the two-line experimental warning immediately before `func Score() Expression`, matching `DocumentMatches` and `GeoDistance`:

```go
// Experimental: Firestore Pipelines is currently in preview and is subject to potential breaking changes in future versions,
// regardless of any other documented package stability guarantees.
```

## Command Records

`cat /Users/junekim/Documents/refactor-equivalence/samples/v2/gcloud-14442/inputs/allowed-files.txt`

```text
firestore/client.go
firestore/pipeline.go
firestore/pipeline_aggregate.go
firestore/pipeline_constant.go
firestore/pipeline_expression.go
firestore/pipeline_field.go
firestore/pipeline_filter_condition.go
firestore/pipeline_function.go
firestore/pipeline_result.go
firestore/pipeline_snapshot.go
firestore/pipeline_source.go
firestore/query.go
vertexai/internal/version.go
```

`go build ./...`

```text
exit_code=0
tail -50:
(no output)
```

`go test ./... -count=1 -short`

```text
exit_code=0
tail -50:
?   	cloud.google.com/go	[no test files]
ok  	cloud.google.com/go/civil	0.210s
ok  	cloud.google.com/go/httpreplay	1.145s
?   	cloud.google.com/go/httpreplay/cmd/httpr	[no test files]
ok  	cloud.google.com/go/httpreplay/internal/proxy	0.216s
ok  	cloud.google.com/go/internal	0.629s
ok  	cloud.google.com/go/internal/btree	1.522s
ok  	cloud.google.com/go/internal/detect	1.205s
ok  	cloud.google.com/go/internal/fields	0.378s
ok  	cloud.google.com/go/internal/leakcheck	6.080s
ok  	cloud.google.com/go/internal/optional	1.490s
ok  	cloud.google.com/go/internal/pretty	1.599s
ok  	cloud.google.com/go/internal/protostruct	2.198s
?   	cloud.google.com/go/internal/pubsub	[no test files]
ok  	cloud.google.com/go/internal/testutil	1.941s
ok  	cloud.google.com/go/internal/trace	1.372s
ok  	cloud.google.com/go/internal/tracecontext	1.768s
ok  	cloud.google.com/go/internal/uid	0.476s
ok  	cloud.google.com/go/internal/version	2.083s
ok  	cloud.google.com/go/rpcreplay	2.108s
?   	cloud.google.com/go/rpcreplay/proto/intstore	[no test files]
?   	cloud.google.com/go/rpcreplay/proto/rpcreplay	[no test files]
?   	cloud.google.com/go/third_party/pkgsite	[no test files]
```
