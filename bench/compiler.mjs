import {measure} from './runner.mjs';
import {cpus} from 'node:os';
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
const fixtures = await import('../test/CompilerFixtures.js');
import {renderSync, render} from '../src/vendor/hyperons.js';

// Compile these ordinary ReScript JSX fixtures in each mode before comparing.
const expected = `<main id="catalog"><h1>Reading room</h1>${Array.from({length: 100}, (_, i) => `<article class="book"><h2>Book ${i}</h2><p>A &lt;writer&gt;</p><footer>Read &amp; enjoy</footer></article>`).join('')}</main>`;
const tree = fixtures.catalog(100);
const cases = [
  {name: 'jsx/catalog100-render', run: () => renderSync(tree), expected},
  {name: 'jsx/catalog100-create-render', run: () => renderSync(fixtures.catalog(100)), expected},
  {name: 'jsx/catalog100-async-render', run: () => render(fixtures.catalog(100)), expected, async: true},
];
const results = [];
for (const benchmark of cases) results.push(await measure(benchmark));
console.log(JSON.stringify({runtime: Bun.version, cpu: cpus()[0]?.model,
  fixtureHash: createHash('sha256').update(readFileSync(new URL('../test/CompilerFixtures.js', import.meta.url))).digest('hex'), results}, null, 2));
