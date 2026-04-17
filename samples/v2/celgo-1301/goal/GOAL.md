# PR #1301 — Support shorthand types in env yaml and REPL 

## PR body

Upstream parser for shorthand type specifier `map<int, string>`. This is used for describing environments.

Add support for parsing yaml environment configs using the string type specifier and update the REPL to use the new format.

Also rework repl to track types in terms of the environment config
TypeDesc. This removes many of the usages of deprecated APIs in the
REPL.
