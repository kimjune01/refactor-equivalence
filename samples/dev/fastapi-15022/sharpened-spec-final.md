# Sharpened refactor spec: final

## Accepted claims

1. In `fastapi/dependencies/utils.py`, keep stream item type detection as a small helper that returns the first type argument for supported generator/iterable return annotations and returns `Any` when the origin is supported but unsubscripted. The helper must return `None` for unsupported annotations. This is testable with `Iterable[int]`, `Iterator[str]`, `Generator[dict, None, None]`, `AsyncIterable[bytes]`, `AsyncIterator[object]`, `AsyncGenerator[int, None]`, unsubscripted supported origins, and non-stream annotations.

2. In `fastapi/dependencies/utils.py`, the helper must remain internal to dependency/routing support and must not alter existing public API names, function signatures, or exception behavior. This bounds the refactor to imports, the stream-origin collection, and helper implementation needed by `fastapi/routing.py`.

3. In `fastapi/routing.py`, keep the construction of response keyword arguments shared by normal, JSONL streaming, and raw streaming response paths so behavior for background tasks, explicit decorator `status_code`, dependency-mutated `response.status_code`, and dependency-set headers remains identical to the pre-streaming path. This is testable with endpoints that set a decorator status code, mutate the injected `Response`, set headers, and attach background tasks.

4. In `fastapi/routing.py`, preserve the existing non-generator endpoint behavior: plain return values must still run through `serialize_response`, keep the `dump_json` fast path when using the default response class and a response field, clear bodies for status codes that disallow bodies, and attach dependency-set headers. This claim is bounded to the non-stream branch in `get_request_handler`.

5. In `fastapi/routing.py`, generator and async-generator endpoints with the default response class and no explicit `response_model` must be treated as JSON Lines streams: call the endpoint once after dependency solving, return a `StreamingResponse`, use media type `application/jsonl`, append exactly one newline-delimited JSON item per yielded value, and preserve the same status-code, header, and background-task behavior as other non-`Response` returns. This is testable with sync and async generator endpoints that yield multiple JSON-serializable values.

6. In `fastapi/routing.py`, when a default-response generator endpoint has an item type inferred from its return annotation, each yielded item must be validated and serialized through the generated stream item `ModelField` using the existing response model include/exclude/by-alias/exclude-unset/exclude-defaults/exclude-none options. Invalid yielded items must raise `ResponseValidationError` with `loc=("response",)` and the yielded item as the body.

7. In `fastapi/routing.py`, when a default-response generator endpoint has no stream item field, each yielded item must be encoded with `jsonable_encoder` and then JSON-encoded as UTF-8 bytes followed by `b"\n"`. This preserves streaming behavior for untyped or unsupported stream annotations without inventing a public response model.

8. In `fastapi/routing.py`, async JSONL streaming and async raw streaming must yield control after each item or chunk with `anyio.sleep(0)`, preserving the cancellation behavior added by the diff. This is bounded to async generator wrappers only.

9. In `fastapi/routing.py`, generator and async-generator endpoints with an explicit `StreamingResponse` response class or subclass must not be converted to JSONL. They must pass the generator through to the configured response class as `content`, while preserving the same response argument and header behavior as other non-`Response` returns. This is testable with an explicit `StreamingResponse` response class.

10. In `fastapi/routing.py`, `APIRoute` must infer `stream_item_type` only when `response_model` is the default placeholder, the endpoint return annotation has a supported stream origin, and the route response class is still the default placeholder. In that JSONL case, `response_model` must be set to `None`. For explicit raw streaming response classes with supported stream return annotations, response-model inference must also be suppressed so FastAPI does not try to create a response model for `Iterable`, `AsyncIterable`, `Generator`, or `AsyncGenerator` annotations. Otherwise existing response-model inference behavior must remain unchanged.

11. In `fastapi/routing.py`, `APIRoute` must create `stream_item_field` only when `stream_item_type` is set, using serialization mode and a deterministic name based on the route unique ID. Routes without an inferred stream item type must have `stream_item_field` set to `None`.

12. In `fastapi/routing.py`, `APIRoute.is_json_stream` must be true only for generator or async-generator endpoint dependants using the default response class and no explicit `response_model`. The value passed into `get_request_handler` must match that route property, and `stream_item_field` must also be passed through unchanged.

13. In `fastapi/openapi/utils.py`, OpenAPI response content for JSONL routes must be emitted only when the route status code allows a body. The response content key must be `application/jsonl`, and it must contain an `itemSchema` derived from `route.stream_item_field` when available or `{}` when unavailable. This is testable by comparing OpenAPI for typed and untyped generator routes.

14. In `fastapi/openapi/utils.py`, non-JSONL response schema generation must keep the existing media type and schema behavior: JSON response classes use the response field when present, JSON responses without a field use `{}`, non-JSON response classes default to `{"type": "string"}`, and no content is emitted when the route response media type is falsey or the status code disallows a body.

15. In `fastapi/openapi/utils.py`, `get_fields_from_routes` must continue to ignore non-`APIRoute` routes and routes excluded from schema, and must include `route.stream_item_field` in the collected response fields when present. This ensures typed JSONL item schemas participate in the same model-name and schema collection pass as normal response fields.

16. All accepted refactor work is bounded to `fastapi/dependencies/utils.py`, `fastapi/routing.py`, and `fastapi/openapi/utils.py`. Any implementation must avoid changes to tests, docs, scripts, dependency metadata, lockfiles, public signatures, exported names, and externally visible exceptions except for the intended response validation errors from invalid streamed items.

## Rejected claims

1. Refactor or keep the `pyproject.toml` Starlette minimum-version change. Rejected because the spec says no new dependencies and no `pyproject.toml` edits, even though the file appears in the allowed-files list.

2. Refactor or keep the `uv.lock` Starlette minimum-version change. Rejected because dependency and lockfile changes are outside the stated no-new-dependencies constraint and are not needed to reduce source complexity in the allowed FastAPI modules.

3. Refactor or keep the `pyproject.toml` Ruff ignores for `docs_src/stream_json_lines` and `docs_src/stream_data`. Rejected because docs are explicitly excluded and these ignores are unrelated to runtime source refactoring.

4. Add or modify tests for JSONL streaming behavior. Rejected for this volley because tests are explicitly outside the allowed edit set for implementation, though the accepted claims are written to be testable by an external harness.

5. Add new public APIs for JSONL streaming configuration. Rejected because the spec requires preserving public API names and signatures; the diff implements behavior through existing route inference and internal helpers.

6. Change behavior for explicit `Response` instances returned by endpoints. Rejected because preserving current FastAPI behavior requires returned `Response` objects to remain authoritative, with only missing background tasks filled as before.

7. Broaden stream detection to arbitrary protocols, custom iterable classes, or `typing_extensions` constructs not already represented by the diff. Rejected because it would expand behavior beyond the introduced change and make the refactor less bounded.

8. Treat every generator endpoint with any explicit `response_class` as raw streaming content. Rejected because non-streaming classes such as `JSONResponse` and `PlainTextResponse` cannot safely serialize generators and should keep existing non-`Response` return handling.

9. Allow default-response generator endpoints with an explicit `response_model` to become JSONL streams while ignoring that explicit response model. Rejected because it would silently drop existing response-model validation and serialization semantics.

10. Leave response-model inference enabled for explicit raw streaming routes annotated as `Iterable`, `AsyncIterable`, `Generator`, or `AsyncGenerator`. Rejected because it breaks documented explicit `StreamingResponse` route shapes by trying to create a response model for stream container annotations.

11. Let JSONL streaming routes fall back to default `200 OK` when a decorator status code or dependency-mutated `Response.status_code` is present. Rejected because it would regress existing FastAPI status-code behavior for non-`Response` endpoint returns.
