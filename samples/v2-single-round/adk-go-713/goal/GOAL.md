# PR #713

Implementation of Cloud Events trigger processing.

This implementation should handle the resource exhausted exceptions with jitter to prevent thundering herd (configured per subrouter).

Similar to https://github.com/google/adk-go/pull/704

(see the details in [go/orcas-rfc-522](http://go/orcas-rfc-522))
