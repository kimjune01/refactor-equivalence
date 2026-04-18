## Build: PASS
## Tests: PASS

## Command Results

Allowed edit set command:

```text
exit code: 1
tail:
/private/tmp/refactor-eq-workdir/cleanroom-v2/1286
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/celgo-1286/inputs/allowed-files.txt: No such file or directory
```

Local cleanroom allowed file artifact used for review:

```text
cel/env.go
cel/options.go
cel/program.go
common/ast/ast.go
common/types/provider.go
```

Build command:

```text
exit code: 0
tail:
EXIT_CODE=0
```

Test command:

```text
exit code: 0
tail:
EXIT_CODE=0
ok  	github.com/google/cel-go/cel	0.447s
ok  	github.com/google/cel-go/checker	1.214s
?   	github.com/google/cel-go/checker/decls	[no test files]
ok  	github.com/google/cel-go/common	0.958s
ok  	github.com/google/cel-go/common/ast	1.635s
ok  	github.com/google/cel-go/common/containers	2.282s
?   	github.com/google/cel-go/common/debug	[no test files]
ok  	github.com/google/cel-go/common/decls	2.054s
ok  	github.com/google/cel-go/common/env	2.516s
?   	github.com/google/cel-go/common/functions	[no test files]
?   	github.com/google/cel-go/common/operators	[no test files]
?   	github.com/google/cel-go/common/overloads	[no test files]
ok  	github.com/google/cel-go/common/runes	0.750s
?   	github.com/google/cel-go/common/stdlib	[no test files]
ok  	github.com/google/cel-go/common/types	0.571s
ok  	github.com/google/cel-go/common/types/pb	1.404s
?   	github.com/google/cel-go/common/types/ref	[no test files]
?   	github.com/google/cel-go/common/types/traits	[no test files]
ok  	github.com/google/cel-go/examples	1.846s
ok  	github.com/google/cel-go/ext	2.853s
ok  	github.com/google/cel-go/interpreter	2.992s
?   	github.com/google/cel-go/interpreter/functions	[no test files]
ok  	github.com/google/cel-go/parser	3.187s
?   	github.com/google/cel-go/parser/gen	[no test files]
?   	github.com/google/cel-go/test	[no test files]
ok  	github.com/google/cel-go/test/bench	2.959s [no tests to run]
?   	github.com/google/cel-go/test/proto2pb	[no test files]
?   	github.com/google/cel-go/test/proto3pb	[no test files]
```

## Finding F1 — SourceInfo.HasExtension only checks the first extension
**Severity**: blocker
**File**: common/ast/ast.go:442
**What**: `HasExtension` returns from inside the loop on the first extension, so an AST whose `json_name` extension is present but not first is treated as if it has no `json_name` extension. This bypasses the program-time guard that is supposed to reject JSON-name ASTs unless `cel.JSONFieldNames(true)` is enabled. Current evidence:

```go
// common/ast/ast.go
441	// HasExtension returns whether the source info contains the extension which satisfies the minimum version requirement.
442	func (s *SourceInfo) HasExtension(id string, minVersion ExtensionVersion) bool {
443		for _, ext := range s.Extensions() {
444			return ext.ID == id && ext.Version.Major >= minVersion.Major && ext.Version.Minor >= minVersion.Minor
445		}
446		return false
447	}
```

```go
// cel/program.go
222	if a.SourceInfo().HasExtension("json_name", ast.NewExtensionVersion(1, 1)) {
223		if !e.HasFeature(featureJSONFieldNames) {
224			return nil, errors.New("the AST extension 'json_name' requires the option cel.JSONFieldNames(true)")
225		}
226	}
```

**Fix**: Continue scanning all extensions and return true only when a matching extension satisfies the minimum version; return false after the loop. Also compare major/minor as a version pair so a higher major with lower minor is not rejected incorrectly.

## Finding F2 — JSONFieldNames(false) does not disable JSON-name lookup on extended envs
**Severity**: blocker
**File**: cel/env.go:851
**What**: Extending a JSON-enabled environment with `JSONFieldNames(false)` clears the feature flag but leaves the copied registry in JSON field-name mode. `Env.Extend` copies the registry including its JSON-name setting, `features()` sets the feature false, and `configure()` only calls `WithJSONFieldNames(true)` when the feature is enabled. There is no corresponding call to `WithJSONFieldNames(false)`. A disabled child env can therefore still type-check and evaluate JSON field-name accesses through the provider, which changes the observable behavior of the option and makes disabling it ineffective after an enabled parent. Current evidence:

```go
// cel/env.go
519		reg := providerReg.Copy()
520		provider = reg
```

```go
// common/types/provider.go
172	// Copy copies the current state of the registry into its own memory space.
173	func (p *Registry) Copy() *Registry {
174		copy := &Registry{
175			revTypeMap: make(map[string]*Type),
176			pbdb:       p.pbdb.Copy(),
177		}
```

```go
// cel/options.go
910	func features(flag int, enabled bool) EnvOption {
911		return func(e *Env) (*Env, error) {
912			e.features[flag] = enabled
913			return e, nil
914		}
915	}
```

```go
// cel/env.go
851	// Enable JSON field names is using a proto-based *types.Registry
852	if e.HasFeature(featureJSONFieldNames) {
853		reg, isReg := e.provider.(*types.Registry)
854		if !isReg {
855			return nil, fmt.Errorf("JSONFieldNames() option is only compatible with *types.Registry providers")
856		}
857		err := reg.WithJSONFieldNames(true)
```

**Fix**: When the JSON field-name feature has been explicitly applied, require a `*types.Registry` provider and call `reg.WithJSONFieldNames(e.HasFeature(featureJSONFieldNames))`, so both true and false states are propagated into the copied registry.
