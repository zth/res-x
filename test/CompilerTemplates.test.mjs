import {test, expect} from 'bun:test';
import * as fixtures from './CompilerFixtures.js';
import {render, renderSync} from '../src/vendor/hyperons.js';

test('templates escape literal and dynamic text exactly once', () => {
  expect(renderSync(fixtures.staticText())).toBe('<div title="&lt;&amp;&quot;&#x27;">&lt;&amp;&gt;&quot;&#x27; 🦊</div>');
  expect(renderSync(fixtures.card('<script>', 'A & B'))).toBe('<article class="book"><h2>&lt;script&gt;</h2><p>A &amp; B</p><footer>Read &amp; enjoy</footer></article>');
});
test('captured expressions run once, left to right, at construction', () => {
  const calls = [];
  const element = fixtures.captureOrder(value => { calls.push(value); return value; });
  expect(calls).toEqual(['first', 'second']);
  expect(renderSync(element)).toBe('<div><span>first</span><span>second</span></div>');
  expect(renderSync(element)).toBe('<div><span>first</span><span>second</span></div>');
  expect(calls).toEqual(['first', 'second']);
});
test('dynamic props and void tags preserve normal rendering', () => {
  expect(renderSync(fixtures.fallback('a & b', '<unsafe>'))).toBe('<section class="a &amp; b"><span>&lt;unsafe&gt;</span><input disabled/></section>');
});
test('component slots retain context and isolate repeated renders', () => {
  expect(renderSync(fixtures.contextual('one'))).toBe('<div><b>one</b></div>');
  expect(renderSync(fixtures.contextual('two'))).toBe('<div><b>two</b></div>');
});
test('async component slots preserve output order and sync rejection', async () => {
  expect(await render(fixtures.asynchronous('<first>'))).toBe('<div><em>&lt;first&gt;</em><span>after</span></div>');
  expect(() => renderSync(fixtures.asynchronous('first'))).toThrow();
});
test('static regions escape attributes, text, and omit an empty class', () => {
  expect(renderSync(fixtures.literal())).toBe('<div title="A &amp; B&#x27;s">&lt;safe&gt; &amp; sound</div>');
});
test('generated static HTML preserves UTF-8 source bytes', () => {
  expect(renderSync(fixtures.unicode())).toBe('<p>🦊 café &lt;&amp;&gt;</p>');
});
test('source locations preserve JSX and captured expressions after Unicode', () => {
  expect(renderSync(fixtures.unicodeBefore())).toBe('<p>🦊 café</p>');
  expect(renderSync(fixtures.unicodeCapture(value => `${value} <&>`))).toBe('<p>🦊 café &lt;&amp;&gt;</p>');
});
