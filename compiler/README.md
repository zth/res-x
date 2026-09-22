# ResX HTML compiler prototype

A standalone Rust/Oxc process optimizes the JavaScript produced by **unmodified stock ReScript**. A bundler plugin applies its edits in memory. There is no generated ReScript project, second ReScript compilation, source rewrite, or runtime compiler.

```text
ordinary app .res files
  → stock ReScript (type checking and JavaScript generation)
  → ResX Oxc transform in the server bundler
  → ordinary application JavaScript bundle
```

## Run the demo

Requires Rust 1.96, Node, and Bun 1.3.14. From the repository root:

```sh
npm ci
bun run compiler:build
cd demo
npm ci
bun run build:vite
bun run build:res:templates
bun run start:templates
```

Open `/catalog`. The entry point is `demo/.resx/optimized/app.mjs`; run it from the demo directory so existing asset paths work. `bun ../compiler/build.mjs --baseline` produces the same application bundle without the transform. `--entry src/YourApp.js` selects another server entry. Compilation happens once before bundling. The build report separates stock compilation and bundling time.

## What gets generated

For an eligible stock JSX factory call such as:

```js
H.Elements.jsx("div", {className: "card", children: title})
```

the transform emits the equivalent of:

```js
H.Elements.template(__resxWriter0, [title])
function __resxWriter0(output, context, values) {
  H.Elements.templateStatic(output, '<div class="card">');
  H.Elements.templateChild(output, context, values[0]);
  H.Elements.templateStatic(output, '</div>');
}
```

Adjacent static regions, including nested native elements, become one string. Dynamic expressions are captured once in their original order. Dynamic children use the existing renderer, preserving escaping, context, async components, and error handling. Writers are private. Stock `.js` files stay untouched; the bundle contains the optimized code.

The current local optimization uses scope-resolved JavaScript bindings, not CMT analysis. It recognizes approved ResX imports, rejects binding mutation/escapes, and handles native tags with literal `className`, `id`, and `title`. Unsupported props and void tags keep ordinary rendering. This assumes the framework runtime ABI is not monkey-patched elsewhere in the application. No cross-module component inlining is attempted. Typed ReScript analysis could later supply additional proofs without changing this integration.

## Integration and performance

`oxc-transform.mjs` provides `transform(code, filename)` and a Vite/Rollup-style adapter. `oxc-bun.mjs` provides the build-time Bun plugin used by the demo. A persistent native process parses modules with Oxc and returns edits; MagicString applies them and generates source maps. Content-addressed caching includes the native binary, adapter version, source, filename, and approved runtime paths. Changes invalidate the affected module automatically.

The Bun application build is tested. The Vite/Rollup adapter is an integration starting point, not a verified watch-mode implementation. Native binary distribution and installation are not packaged yet. The compiler remains opt-in and is not included in the published npm package.

## Verification and measurement

```sh
bun test compiler/oxc.test.mjs
bun compiler/check.mjs
bun compiler/check-demo.mjs
bun bench/compiler.mjs
bun bench/compiler.mjs --optimized
```

The framework suite runs against both baseline and transformed bundles. Dedicated compiler tests inspect generated code and fallback behavior. The demo check compares HTTP status, HTML, and CSS. Benchmarks compile before timing, validate output before and after samples, and compare the same stock fixture with/without optimization. Run each mode in fresh processes, serially. Results belong in the PR description, not checked-in measurement snapshots.
