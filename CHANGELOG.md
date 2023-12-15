# master

- Create target directory if it doesn't already exist.
- Remove unused `server` in `renderConfig`.

# 0.1.0-alpha.7

- Support removing elements with client actions.

# 0.1.0-alpha.6

- Fix issue with children in JSX.

# 0.1.0-alpha.5

- Fix dependency on `rescript-bun`.
- Add `BunUtils.URLSearchParams.copy` helper.
- Rename handler creators: `get` -> `hxGet`, `makeGet` -> `makeHxGetIdentifier`, `implementGet` -> `implementHxGetIdentifier`. Same for post/put/delete/patch.

# 0.1.0-alpha.4

- Add `hxGet/Post/Put/Delete/Patch` helpers suitable for when you need to handle cyclic dependencies.

# 0.1.0-alpha.3

- Include all files in package.

# 0.1.0-alpha.2

- Fix package name in `rescript.json`.
- Fix various smaller things.
