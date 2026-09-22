# Experimental HTML templates

This opt-in prototype compiles ordinary, already type-checked ResX JSX into
module-level HTML writers. Components still use `@jsx.component`, native JSX,
`Hjsx.string`, and ordinary expressions. No template annotation or new authoring
API is required. It changes server output code, not browser dependencies.

## Try it

Use ReScript **12.3.0** and a matching ReScript compiler source checkout. Building
the custom compiler requires OCaml 5.3, dune (>=3.17), and cppo on `PATH`:

```sh
opam install /path/to/rescript-compiler/rescript.opam --deps-only
opam exec -- node compiler/build-toolchain.mjs /path/to/rescript-compiler
node compiler/check.mjs
cd demo
npm install
bun run link:resx
bun run build:vite
bun run build:res:templates
PORT=4444 bun run start
```

Visit `/catalog`. Its source is `demo/src/Catalog.res`; compare the emitted
`demo/src/Catalog.js`. The reading-room page uses the same JSX as any other ResX
page. Existing demo pages also participate automatically.

The toolchain builder reads the supplied checkout's **v12.3.0 tag**, creates
an isolated ignored cache, installs the pass and one backend hook, and builds
only the compiler executable. The upstream opam manifest includes ReScript's
pinned Flow parser dependency; installing only dune and cppo is insufficient. It never modifies the supplied checkout. This is
a source-built prototype, not a published compiler distribution. It has been
targeted at upstream ReScript `v12.3.0` (`44b1e4d22`).

`RESX_BSC=/absolute/path/to/custom/bsc node compiler/build.mjs` can use an already
built executable instead. `RESX_COMPILER_REPORT=1` reports transformed locations.
The wrapper cleans when switching compiler binaries or optimization modes;
ordinary incremental builds work within one mode. Use `node compiler/build.mjs
--baseline` for a reliable baseline build. Do not mix the wrapper with direct
`rescript` builds without cleaning: ReScript does not track this optimization's
environment variable in its cache. Watch mode is not integrated yet.

## Boundaries

The pass combines nested native elements, literal text, and literal `className`,
`id`, and `title` attributes. Dynamic children become captured slots. Static HTML
is escaped once at build time; captured children use the existing renderer.
Native element and props allocations disappear inside a combined region.

Dynamic attributes, spreads, style objects, raw HTML, void elements, and source
strings containing escape sequences use the normal rendering path. Supported
children inside those elements can still specialize. Components retain their
existing evaluation, context, and asynchronous rendering behavior. There is no
whole-app constant evaluation, component inlining, ResGraph analysis, or
streaming optimization in this first pass.

The runtime helpers in `Hjsx.Elements` are an internal experimental ABI, not an
API app authors should call. Compiler and runtime changes should be reviewed and
versioned together before making this generally available.

## Verify and measure

`node compiler/check.mjs` runs the full suite in both modes, verifies byte-identical
catalog output, checks emitted specialization, and verifies invalid JSX props
still fail type checking. After building demo assets, `node compiler/check-demo.mjs`
compares catalog, start, and 404 HTTP responses between modes. After installing demo dependencies and building Vite assets,
`node compiler/check-demo.mjs` compares actual catalog, start, and 404 HTTP
responses between modes. `bun bench/compiler.mjs` measures the currently built
JSX fixtures, using the existing benchmark harness (one-second warmup, nine
samples). Compare fresh baseline and template builds on the same machine, with
no other builds or benchmarks running. Keep measurements in the PR description.
