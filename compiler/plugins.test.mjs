import {test, expect} from 'bun:test';
import {mkdtempSync, writeFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join, resolve} from 'node:path';
import {resxBunPlugin} from './oxc-bun.mjs';
import {resxOxcPlugin} from './oxc-transform.mjs';
import {build as viteBuild} from 'vite';
import {execFileSync} from 'node:child_process';
const runtime = resolve('src/Hjsx.js');
const renderer = resolve('src/vendor/hyperons.js');
const source = text => `import * as H from ${JSON.stringify(runtime)}; import {renderSync} from ${JSON.stringify(renderer)};
export const html = renderSync(H.Elements.jsx('p', {children: ${JSON.stringify(text)}}));`;
let serial = 0;
function evaluate(directory, code) {
  const output = join(directory, `output-${serial++}.mjs`);
  writeFileSync(output, code);
  return JSON.parse(execFileSync('bun', ['-e', `console.log(JSON.stringify((await import(${JSON.stringify(output)})).html));`], {encoding: 'utf8'}));
}

test('Bun plugin owns compiler lifecycle across successive builds and source edits', async () => {
  const directory = mkdtempSync(join(tmpdir(), 'resx-plugin-'));
  try {
    const entry = join(directory, 'app.js');
    const plugin = resxBunPlugin({cacheDir: join(directory, 'cache')});
    for (const text of ['first', 'first', '<changed>']) {
      writeFileSync(entry, source(text));
      const result = await Bun.build({entrypoints: [entry], target: 'bun', format: 'esm', plugins: [plugin]});
      expect(result.success).toBe(true);
      expect(await evaluate(directory, await result.outputs[0].text())).toBe(text === '<changed>' ? '<p>&lt;changed&gt;</p>' : '<p>first</p>');
    }
  } finally { rmSync(directory, {recursive: true, force: true}); }
});

test('Bun leaves unchanged modules available to subsequent loader plugins', async () => {
  const directory = mkdtempSync(join(tmpdir(), 'resx-loader-'));
  try {
    const entry = join(directory, 'custom.js');
    writeFileSync(entry, 'handled by another plugin');
    const result = await Bun.build({entrypoints: [entry], target: 'bun', plugins: [resxBunPlugin(), {
      name: 'custom-loader', setup(build) {
        build.onLoad({filter: /custom\.js$/}, () => ({contents: 'export const html = "handled";', loader: 'js'}));
      },
    }]});
    expect(result.success).toBe(true);
    expect(await evaluate(directory, await result.outputs[0].text())).toBe('handled');
  } finally { rmSync(directory, {recursive: true, force: true}); }
});

test('Vite/Rollup plugin can be reused across production builds and source edits', async () => {
  const directory = mkdtempSync(join(tmpdir(), 'resx-rollup-'));
  try {
    const entry = join(directory, 'app.mjs');
    const plugin = resxOxcPlugin();
    for (const text of ['before', 'after']) {
      writeFileSync(entry, source(text));
      const result = await viteBuild({configFile: false, root: directory, logLevel: 'silent', plugins: [plugin],
        build: {write: false, minify: false, lib: {entry, formats: ['es'], fileName: 'app'}, commonjsOptions: {include: [/Hjsx\.js$/]}}});
      const code = result[0].output.find(output => output.type === 'chunk').code;
      expect(code).toContain('.template(');
      expect(evaluate(directory, code)).toBe(`<p>${text}</p>`);
    }
  } finally { rmSync(directory, {recursive: true, force: true}); }
});
