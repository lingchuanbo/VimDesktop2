# vendor

`vendor/` is reserved for third-party bundled dependencies that are not part of VimDesktop runtime code.

Suggested usage:
- external DLLs
- embedded portable tools
- upstream packages copied into the repo

Keep runtime glue code in `src/` or `libs/`, not here.
