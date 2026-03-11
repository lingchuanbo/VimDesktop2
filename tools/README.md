# tools

`tools/` is the preferred location for workspace-managed executables and helper apps.

Current compatibility rules:
- `PathResolver.AppsPath()` checks `tools/` first.
- Existing files under `apps/` continue to work.
- New tool binaries should be added under `tools/`.
