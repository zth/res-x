import {measure} from './runner.mjs';
import {cpus} from 'node:os';
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
const fixturePath = fileURLToPath(new URL('../test/CompilerFixtures.js', import.meta.url));
let code = readFileSync(fixturePath, 'utf8');
const optimized = process.argv.includes('--optimized');
if (optimized) {
  const {createResxTransform} = await import('../compiler/oxc-transform.mjs');
  const transform = createResxTransform();
  try { code = (await transform.transform(code, fixturePath)).code; }
  finally { transform.close(); }
}
const module = {exports: {}};
new Function('require', 'module', 'exports', code)(createRequire(fixturePath), module, module.exports);
const fixtures = module.exports;
import {make} from '../src/Handlers.js';
import {renderSync, render} from '../src/vendor/hyperons.js';

// Compile these ordinary ReScript JSX fixtures in each mode before comparing.
const expected = `<main id="catalog"><h1>Reading room</h1>${Array.from({length: 100}, (_, i) => `<article class="book"><h2>Book ${i}</h2><p>A &lt;writer&gt;</p><footer>Read &amp; enjoy</footer></article>`).join('')}</main>`;
const tree = fixtures.catalog(100);
const handler = make(async () => undefined);
const cases = [
  {name: 'jsx/catalog100-render', run: () => renderSync(tree), expected},
  {name: 'jsx/catalog100-create-render', run: () => renderSync(fixtures.catalog(100)), expected},
  {name: 'jsx/catalog100-async-render', run: () => render(fixtures.catalog(100)), expected, async: true},
  {name: 'jsx/catalog100-request', run: () => handler.handleRequest({request: new Request('http://localhost/catalog'), render: async () => fixtures.catalog(100)}).then(response => response.text()), expected: '<!DOCTYPE html>' + expected, async: true},
];
const results = [];
for (const benchmark of cases) results.push(await measure(benchmark));
console.log(JSON.stringify({optimized, runtime: Bun.version, cpu: cpus()[0]?.model,
  fixtureHash: createHash('sha256').update(readFileSync(new URL('../test/CompilerFixtures.js', import.meta.url))).digest('hex'), results}, null, 2));
