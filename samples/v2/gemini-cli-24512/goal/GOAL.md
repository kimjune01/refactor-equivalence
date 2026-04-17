# PR #24512 — feat(ui): enable "TerminalBuffer" mode to solve flicker

## PR body

This PR introduces a new `TerminalBuffer` rendering mode to resolve UI flicker issues experienced in the traditional alternate buffer mode.

### Key Changes
*   **Terminal Buffer Mode:** Introduces `TerminalBuffer` for a smooth, flicker-free rendering experience by leveraging static rendering for history items.
*   **Settings Updates:** Adds `renderProcess` and `terminalBuffer` configuration options to customize the rendering strategy.
*   **Serializer Fixes:** Fixes the terminal serializer to correctly handle and preserve wide characters (multi-byte unicode) during rendering.
*   **Mouse Mode Toggle:** Adds a new shortcut to toggle mouse mode explicitly, managing scrollback behaviour cleanly.
*   **Debug Tooling:** Incorporates new commands for dumping frame data and recording sessions to aid UI development.

### Motivation
The standard Ink alternate buffer mode relies on full-screen rewrites which causes flicker, especially on slower terminal emulators. `TerminalBuffer` separates static content (chat history) from dynamic elements (input prompt, spinners), drastically reducing the screen area that needs redrawing.

### Fixed Issues
*   Fixes #14411
*   Resolves general terminal rendering flicker in alternate buffer mode.

## Linked issues
(none)
