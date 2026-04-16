# Volley Round 1: Refactor Claims

## Accepted Claims

1. In `fastapi/_compat/v2.py`, keep the new Pydantic v2 JSON-byte serialization behavior on `ModelField`: a caller must be able to serialize an already-validated value by delegating to `self._type_adapter.dump_json(...)` and receive `bytes`.
   - Testable by constructing a v2 `ModelField`, validating a value, calling the JSON-byte path, and asserting the result is `bytes` containing the same JSON payload FastAPI would otherwise emit.
   - Justification: the input diff adds a Pydantic-core fast path that avoids `dump_python(mode="json")` plus later `json.dumps()`.

2. The JSON-byte serialization path in `fastapi/_compat/v2.py` must pass through the same response-model filtering options as the existing `serialize` path: `include`, `exclude`, `by_alias`, `exclude_unset`, `exclude_defaults`, and `exclude_none`.
   - Testable by using a response model with aliases, defaults, unset fields, nullable fields, and include/exclude filters, then comparing decoded JSON-byte output against the existing `serialize(..., mode="json")` semantics.
   - Justification: the diff intends a performance refactor only; response-model projection behavior is public FastAPI behavior.

3. Do not change `ModelField.serialize(...)` in `fastapi/_compat/v2.py`: its public signature, default `mode="json"`, return type behavior, and delegation to `self._type_adapter.dump_python(...)` must remain available.
   - Testable by calling existing uses of `field.serialize(...)` with and without `mode` and asserting they still return the same Python objects as before this diff.
   - Justification: callers outside the new fast path still depend on the existing method.

4. In `fastapi/routing.py`, `serialize_response(...)` must preserve its existing behavior when `dump_json` is omitted or false.
   - Testable by calling `serialize_response` without `dump_json` for both `field is None` and `field is not None`, and asserting it still returns `jsonable_encoder(response_content)` for no field and `field.serialize(...)` output for a field.
   - Justification: the new parameter defaults to false, so existing internal and external callers should not observe a behavior change.

5. In `fastapi/routing.py`, response validation must happen exactly as before serialization selection: coroutine endpoints must call `field.validate(...)` directly, sync endpoints must call it through `run_in_threadpool(...)`, and `ResponseValidationError` must still include the original `response_content` and endpoint context.
   - Testable by exercising valid and invalid response models on both sync and async routes and comparing error type, error body, and endpoint context.
   - Justification: the diff changes only the serialization backend after validation succeeds.

6. In `fastapi/routing.py`, when `serialize_response(..., dump_json=True)` is called with a response field and validation succeeds, it must use the JSON-byte serialization path and return those bytes rather than Python data structures.
   - Testable by substituting a field object with distinguishable `serialize` and `serialize_json` methods, or by asserting the returned value is JSON `bytes` for a Pydantic v2 response field.
   - Justification: this is the behavior introduced by the input diff and is the reason `get_request_handler` can bypass `JSONResponse.render`.

7. In `fastapi/routing.py`, `dump_json=True` must not alter the no-response-field branch of `serialize_response(...)`.
   - Testable by calling `serialize_response(field=None, response_content=..., dump_json=True)` and asserting it still returns `jsonable_encoder(response_content)`, not raw JSON bytes.
   - Justification: the fast path requires a response field with a Pydantic `TypeAdapter`; no-field responses have no such validated value.

8. In `fastapi/routing.py`, `get_request_handler(...)` may take the JSON-byte fast path only when both conditions from the diff hold: `response_field is not None` and the route's `response_class` argument is a `DefaultPlaceholder`.
   - Testable with routes that have a response model and default response class, no response model, and explicit response classes such as `JSONResponse`, `ORJSONResponse`, `PlainTextResponse`, or custom `Response` subclasses.
   - Justification: explicit response classes are user-selected rendering behavior and must not be bypassed.

9. In `fastapi/routing.py`, when the JSON-byte fast path is used, construct a plain Starlette/FastAPI `Response` with `content` set to the serialized bytes and `media_type="application/json"`, while preserving the same `response_args` used by the non-fast path.
   - Testable by asserting status code, background tasks, and JSON media type on a default-response-class route with a response model.
   - Justification: the bytes are already rendered JSON, so passing them through `JSONResponse` would double-encode or redundantly render them.

10. In `fastapi/routing.py`, status-code handling and body suppression must remain unchanged around the fast path: `status_code`, `solved_result.response.status_code`, `is_body_allowed_for_status_code(...)`, and `response.headers.raw.extend(...)` must still be applied.
    - Testable with routes returning normal bodies, `204`/`304`-style empty-body status codes, dependency-set status codes, and dependency-set headers.
    - Justification: the refactor must not change HTTP semantics outside serialization implementation.

11. Refactoring may introduce a small helper in `fastapi/routing.py` only if it keeps the current branch conditions and response construction behavior test-equivalent.
    - Testable by inspecting that any helper is called from `get_request_handler(...)` with the same inputs and by route-level tests covering the fast and non-fast paths.
    - Justification: the spec asks to reduce complexity and flatten control flow, but not to broaden behavior.

12. All implementation changes must be limited to `fastapi/_compat/v2.py` and `fastapi/routing.py`.
    - Testable by checking the changed-file list against `FORGE_ALLOWED_FILES.txt`.
    - Justification: those are the only allowed files and the diff touches only those modules.

13. The refactor must not add dependencies, change exported public names, or change callable signatures except for preserving the `dump_json: bool = False` parameter introduced on `serialize_response(...)`.
    - Testable by checking `pyproject.toml` is untouched and introspecting the affected callable signatures.
    - Justification: the original spec requires preserved public API and no dependency changes.

## Rejected Claims

1. Reject changing tests, docs, `docs_src/**`, `scripts/**`, or any file outside `fastapi/_compat/v2.py` and `fastapi/routing.py`.
   - Reason: outside the allowed set and explicitly disallowed by the input spec.

2. Reject replacing all default JSON responses with raw `Response` construction.
   - Reason: the diff's fast path is bounded to routes with a response model; no-field responses still rely on existing response-class rendering.

3. Reject applying the JSON-byte fast path when an explicit response class is provided, even if that class is `JSONResponse`.
   - Reason: explicit response classes are part of route behavior and may customize rendering, headers, media type, or subclass behavior.

4. Reject changing validation order, skipping validation, or serializing raw endpoint return values before `field.validate(...)`.
   - Reason: FastAPI response-model validation and error reporting must remain unchanged.

5. Reject changing error classes, error payload shape, endpoint context extraction, or exception chaining.
   - Reason: the refactor is about serialization complexity/performance, not validation or diagnostics behavior.

6. Reject adding a Pydantic-v1-compatible `serialize_json` implementation in this task.
   - Reason: the allowed diff only modifies `fastapi/_compat/v2.py`; extending v1 compatibility is outside scope and outside the observed change.

7. Reject using `json.dumps`, `jsonable_encoder`, or `field.serialize(...)` inside the JSON-byte fast path after validation succeeds.
   - Reason: that would undo the performance behavior introduced by delegating directly to Pydantic's `dump_json(...)`.

8. Reject changing media type away from `application/json` for the fast-path `Response`.
   - Reason: the bypassed default response is JSON-oriented, and clients should still receive JSON media type.

9. Reject altering status-code precedence or header propagation while extracting helpers.
   - Reason: those behaviors are adjacent to the new code but are not part of the intended refactor.

10. Reject broad cleanups, renames, formatting churn, or abstraction changes unrelated to the introduced JSON-byte serialization branch.
    - Reason: the task is bounded to reducing complexity introduced by the diff without changing behavior.
