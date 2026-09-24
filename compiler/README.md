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

Bun and Vite/Rollup production builds are tested, including successive builds with changed source. Full development-server watch/HMR integration is not yet verified. Native binary distribution and installation are not packaged yet. The compiler remains opt-in and is not included in the published npm package.

## Verification and measurement

```sh
bun test compiler/oxc.test.mjs compiler/plugins.test.mjs
bun compiler/check.mjs
bun compiler/check-demo.mjs
bun bench/compiler.mjs
bun bench/compiler.mjs --optimized
```

The framework suite runs against both baseline and transformed bundles. Compiler tests also generate 60 combinations of attributes and children and compare optimized/unoptimized HTML and evaluation order. Dedicated compiler tests inspect generated code and fallback behavior. The demo check compares HTTP status, HTML, and CSS. Benchmarks compile before timing, validate output before and after samples, and compare the same stock fixture with/without optimization. Run each mode in fresh processes, serially. Results belong in the PR description, not checked-in measurement snapshots.

## A normal server-bundler plugin

After stock ReScript generates JavaScript, the build integration is just:

```js
import {resxBunPlugin} from "../compiler/oxc-bun.mjs";

await Bun.build({
  entrypoints: ["src/Demo.js"],
  target: "bun",
  outdir: "dist-server",
  plugins: [resxBunPlugin()],
});
```

The plugin starts and closes its compiler worker automatically for each build. Reusing the plugin for another build is supported. Modules that are not transformed remain available to other loader plugins. The in-memory cache retains only the latest source version per file.

Add the transform to the **server** bundle pipeline. The existing `res-x-vite-plugin.mjs` primarily builds browser assets; adding an HTML transform to that assets-only build would not optimize the server entry point. `resxOxcPlugin()` is available for server builds using Vite/Rollup, with lazy initialization and cleanup on bundle/watcher closure or build errors.

## Keep the compiler local and small

The compiler recognizes known runtime calls, builds a sequence of static HTML and dynamic child slots, and emits private writers. Adjacent static text is combined as it is collected. Generated names use Oxc's decoded symbol/reference information, including names in nested scopes, and writer parameters avoid capturing the runtime import. Existing runtime helpers own dynamic rendering semantics.

Useful references for this design:

- [Solid's SSR template transform](https://github.com/ryansolid/dom-expressions/blob/main/packages/babel-plugin-jsx-dom-expressions/src/ssr/template.js) hoists static templates and uses scope-aware generated identifiers. It also deduplicates templates; that is a possible later size optimization, not implemented here.
- [Vue's SSR code generation](https://github.com/vuejs/core/blob/main/packages/compiler-ssr/src/ssrCodegenTransform.ts) combines adjacent string parts while building output and delegates interpolation to runtime helpers.
- [solid-jsx-oxc](https://github.com/frank-iii/solid-jsx-oxc) demonstrates native Rust/Oxc transforms packaged behind ordinary bundler plugins and N-API bindings. N-API is a packaging option to evaluate if subprocess overhead becomes material; this prototype keeps its standalone executable.

The useful next integration step is prebuilt native binaries and a standard server-build entry point. Local attribute coverage can grow with differential tests against the renderer. A separate typed-analysis stage or cross-module optimizer is not required by this design.
