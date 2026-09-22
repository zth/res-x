# Standalone ResX compiler prototype

ResX reads the **stock ReScript compiler's `.cmt` artifacts**, generates an
optimized ReScript application in `.resx/build/`, and invokes **the same stock
compiler** to turn it into JavaScript. It never patches or substitutes `bsc`.

```text
Original .res ── stock ReScript ── .cmt
                                    │
                            standalone ResX analyzer
                                    │
                        .resx/build/**/*.res
                                    │
                             stock ReScript
                                    │
                        .resx/build/**/*.js
```

The architecture follows ResGraph's typed-artifact reader/generator approach.
The native analyzer links against unmodified ReScript typed-tree/CMT libraries;
it does not implement a JavaScript backend or link the compiler backend. This
first pass is local JSX analysis; ResGraph-style cross-module resolution and
whole-program specialization remain future work.

## Build the analyzer once

The prototype supports ReScript **12.3.0**. It currently requires a source-built
analyzer (OCaml 5.3, dune, and upstream library dependencies); distributing
prebuilt analyzer binaries is separate packaging work.

```sh
npm ci
# Use a ReScript source checkout containing the upstream v12.3.0 tag.
opam install /path/to/rescript-compiler/rescript.opam --deps-only
opam exec -- node compiler/build-analyzer.mjs /path/to/rescript-compiler
```

The builder extracts the upstream tag into an ignored cache and adds only the
standalone executable's source/build definition. No existing compiler source is
changed, and no ReScript compiler executable is built. Re-run after changing the
analyzer. `RESX_ANALYZER=/path/to/resx_templates.exe` can select an existing build.

## Build and run the demo

```sh
cd demo
npm ci
bun run build:vite
bun run build:res:templates
PORT=4444 bun run start:templates
```

Open `/catalog`. `src/Catalog.res` stays ordinary JSX. Inspect:

- `.resx/build/src/Catalog.res`: generated ReScript with private HTML writers.
- `.resx/build/src/Catalog.js`: the stock compiler's optimized JavaScript.
- `.resx/build/src/Demo.js`: the generated application's entry point.
- `.resx/build-report.json`: module/template counts and build-stage durations.

The generated application mirrors local modules, JavaScript FFI, and assets and
uses the installed dependencies through a symlink. Run it from `.resx/build/` so
relative filesystem asset paths work. This is a local build directory, not yet a
self-contained deployment bundle. The original `bun run build:res` and
`bun run start` remain the ordinary stock-built application.

The wrapper first runs stock ReScript on original sources, then generates and
compiles the separate application. Original source and JavaScript are never
rewritten with optimized code. `RESCRIPT_BSC_EXE` is deliberately not passed to
either stage. Both stages must use the npm-installed compiler.

## Optimization and boundaries

Eligible native JSX regions become static HTML chunks and captured child slots.
Private writer functions are created at module initialization. Static HTML is
escaped at build time; dynamic children retain the existing renderer's escaping,
context, component, and asynchronous behavior. Stock ReScript type-checks both
the authored program and the generated program.

Supported: nested native elements, literal text, and literal class/id/title.
Dynamic attributes, spreads, style, raw HTML, void elements, and escaped source
literals conservatively use normal rendering; supported descendants can still
specialize. Application authoring requires no template annotations.

The analyzer verifies source digests against CMT artifacts and rejects stale or
partial input. Source ranges preserve original dynamic expressions; generated
helpers use `%%private` to preserve public exports. UTF-16 compiler columns are
converted to UTF-8 byte offsets before source edits.

Current integration limits: `jsx.module = Hjsx`, source directories within the
project, and project-local transformations. Dependencies are not rewritten. The
generated project is rebuilt from scratch each time; the first stock stage can
be incremental. Watch integration and incremental generated-project updates are
not implemented. A cold optimized build includes two stock compilation stages.

## Verify and measure

```sh
node compiler/check.mjs
# After building demo assets:
node compiler/check-demo.mjs
```

Checks run the full suite against both applications, verify identical HTML and
public exports, unchanged authored source/stock JS, actual stock compiler identity,
rejection of stale CMTs and invalid JSX, and actual demo HTTP/stylesheet parity.

After `node compiler/build.mjs`, benchmark each application in fresh processes:

```sh
bun bench/compiler.mjs
(cd .resx/build && bun bench/compiler.mjs)
```

Both use the existing benchmark harness: one-second warmup and nine samples.
Run serially with no concurrent builds. Keep measurements in the PR description,
not committed experiment logs. `build-report.json` records timings for the last
local build only.
