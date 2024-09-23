# master

# 0.1.2

- Add `allowEmptyString` option to `FormDataHelpers.getString`, and make sure that empty strings are treated as `None` by default.
- Handle `on` and `off` values for `FormDataHelpers.getBool`.

# 0.1.1

- Fix issue with Vite transform and CSS files with imports.

# 0.1.0

- Move to using a generic JSX transform.

These versions are now required:

- `rescript@>=11.1.0-rc.2`
- `@rescript/core@>=1.0.0`
- `rescript-bun@>=0.4.1`

# 0.1.0-beta.6

- Add `SwapClass` to ResX client actions.

# 0.1.0-beta.5

- BREAKING: Restructure hx handler code.

# 0.1.0-beta.4

- Add `Security` module, and move HTML escaping to use Bun's builtin `escapeHTML`.
- BREAKING: Change types of `domProps.method` and `domProps.action`.
- Add `formAction` handler support.
- Prefix HTMX handler routes automatically.
- Alias `domProps` in the right place so we get completion.

# 0.1.0-beta.3

- Add `renderSyncToString` API.

# 0.1.0-beta.2

- Bind basic version of `hxTarget`.

# 0.1.0-beta.1

- Upgrade `rescript-bun` to `0.3.0`.

# 0.1.0-alpha.10

- Add `onBeforeSendResponse` hook.

# 0.1.0-alpha.9

- Escape title segments.
- Fix bug with races in appending content to `<head>`.

# 0.1.0-alpha.8

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
