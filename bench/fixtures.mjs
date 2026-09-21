import assert from 'node:assert/strict';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {AsyncLocalStorage} from 'node:async_hooks';

// Load the same workloads against either checkout, including its compiled framework.
const root = resolve(process.env.BENCH_ROOT || new URL('..', import.meta.url).pathname);
const load = path => import(pathToFileURL(resolve(root, path)).href);
export const renderer = await load('src/vendor/hyperons.js');
export const handlers = await load('src/Handlers.js');
const controllers = await load('src/RequestController.js');
const h = renderer.jsx ?? renderer.h;
const {Fragment, createRaw, render, renderSync, createContext, useContext} = renderer;
const rowHTML = i => `<li class="item" data-index="${i}"><a href="/items/${i}">Item ${i} &amp; details</a><span>${i}</span></li>`;
export const listHTML = count => `<ul>${Array.from({length: count}, (_, i) => rowHTML(i)).join('')}</ul>`;
export const list = count => h('ul', {children: Array.from({length: count}, (_, i) => h('li', {
  className: 'item', 'data-index': i, children: [h('a', {href: `/items/${i}`, children: `Item ${i} & details`}), h('span', {children: [i]})],
}))});
const page = body => h('html', {children: [h('head', {}), h('body', {children: body})]});
const pageHTML = body => `<html><head></head><body>${body}</body></html>`;
const sync = (name, run, expected) => ({name, run, expected, async: false});
const asynchronous = (name, run, expected) => ({name, run, expected, async: true});

export function createCases() {
  const tree = list(100);
  const encoder = new TextEncoder();
  const text = 'Safe plain text. '.repeat(256);
  const escaped = '<>&"\''.repeat(256);
  const attrs = h('input', {className: 'field', disabled: true, defaultValue: '<&', tabIndex: 2,
    'aria-hidden': false, __rawProps: {'data-json': {x: '<'}, 'bad name': 'ignored'}});
  const styled = h('div', {style: {backgroundColor: 'red', marginTop: 10, opacity: 0.5, msTransition: 'all', '--gap': '2em'}, children: 'styled'});
  const ctx = createContext('default');
  const Consumer = () => h('span', {children: useContext(ctx)});
  let contextTree = h(Consumer, {});
  for (let i = 0; i < 20; i++) contextTree = h(ctx.Provider, {value: `level-${i}`, children: contextTree});
  const componentTree = h(Fragment, {children: Array.from({length: 100}, (_, i) => h(({value}) => h('b', {children: [value]}), {value: i}))});
  const componentHTML = Array.from({length: 100}, (_, i) => `<b>${i}</b>`).join('');
  const sparse = () => h('main', {children: [list(100), Promise.resolve(h('footer', {children: 'done'}))]});
  const manyAsync = () => h('ul', {children: Array.from({length: 100}, (_, i) => Promise.resolve(h('li', {children: [i]})))});
  const manyHTML = `<ul>${Array.from({length: 100}, (_, i) => `<li>${i}</li>`).join('')}</ul>`;
  const storage = new AsyncLocalStorage();
  const store = {value: 7};
  const handler = handlers.make(async request => ({id: new URL(request.url).searchParams.get('id')}));
  const request = (body, extras = {}) => handler.handleRequest({
    request: new Request('http://localhost/bench/items?id=42'), render: async () => body(), ...extras,
  }).then(response => response.text());
  const allow = async () => ({TAG: 'Allow', _0: undefined});
  const routed = handlers.make(async () => null);
  for (let i = 0; i < 1000; i++) routed.hxGet(`/item-${i}`, allow, async () => h('p', {children: 'route'}), false);
  const route = path => routed.handleRequest({request: new Request(`http://localhost${path}`), render: async () => 'fallback'}).then(r => r.text());
  return [
    sync('html/text-safe-4k', () => renderSync(text), text),
    sync('html/text-escaped', () => renderSync(escaped), '&lt;&gt;&amp;&quot;&#x27;'.repeat(256)),
    sync('html/attributes', () => renderSync(attrs), '<input class="field" disabled value="&lt;&amp;" tabindex="2" aria-hidden="false" data-json="{&quot;x&quot;:&quot;&lt;&quot;}"/>'),
    sync('html/styles', () => renderSync(styled), '<div style="background-color:red;margin-top:10px;opacity:0.5;-ms-transition:all;--gap:2em;">styled</div>'),
    sync('html/list-100', () => renderSync(tree), listHTML(100)),
    sync('html/list-100-utf8', () => encoder.encode(renderSync(tree)).byteLength, Buffer.byteLength(listHTML(100))),
    sync('html/create-and-render-100', () => renderSync(list(100)), listHTML(100)),
    sync('html/components-100', () => renderSync(componentTree), componentHTML),
    sync('html/context-depth-20', () => renderSync(contextTree), '<span>level-0</span>'),
    sync('html/raw-4k', () => renderSync(createRaw(text)), text),
    asynchronous('html/small-sync-async-api', () => render(h('p', {children: 'hello'})), '<p>hello</p>'),
    asynchronous('html/single-promise', () => render(Promise.resolve('hello')), 'hello'),
    asynchronous('html/async-api-sync-tree', () => render(tree), listHTML(100)),
    asynchronous('html/async-sparse', () => render(sparse()), `<main>${listHTML(100)}<footer>done</footer></main>`),
    asynchronous('html/stream-async-tail', async () => {const chunks = []; await render(sparse(), c => chunks.push(c)); return chunks.join('');}, `<main>${listHTML(100)}<footer>done</footer></main>`),
    asynchronous('html/async-dense-100', () => render(manyAsync()), manyHTML),
    asynchronous('html/async-nested', () => render(Promise.resolve(h('div', {children: Promise.resolve(tree)}))), `<div>${listHTML(100)}</div>`),
    asynchronous('html/stream-sync-tree', async () => {const chunks = []; await render(tree, c => chunks.push(c)); return chunks.join('');}, listHTML(100)),
    sync('context/als-run', () => storage.run(store, () => storage.getStore().value), 7),
    sync('context/als-read-100', () => storage.run(store, () => {let total = 0; for (let i = 0; i < 100; i++) total += storage.getStore().value; return total;}), 700),
    asynchronous('context/als-await', () => storage.run(store, async () => {await Promise.resolve(); return storage.getStore().value;}), 7),
    sync('request/controller', () => {const c = controllers.make(); c.setStatus(201); c.appendTitleSegment('A'); c.prependTitleSegment('B'); return `${c.getCurrentStatus()}:${c.getTitleSegments().join('|')}`;}, '201:B|A'),
    asynchronous('request/minimal', () => request(() => 'hello'), '<!DOCTYPE html>hello'),
    asynchronous('request/page-100', () => request(() => page(list(100))), `<!DOCTYPE html>${pageHTML(listHTML(100))}`),
    asynchronous('request/context-components-100', () => request(() => h(Fragment, {children: Array.from({length: 100}, () => h(() => handler.useContext().context.id, {}))})), '<!DOCTYPE html>' + '42'.repeat(100)),
    asynchronous('request/head-title-body', () => request(() => page('body'), {onAfterBuildResponse: async ({requestController: c}) => {
      c.appendTitleSegment('A & B'); c.appendToHead(h('meta', {name: 'test'})); c.appendBeforeBodyEnd(h('script', {src: '/app.js'}));
    }}), '<!DOCTYPE html><html><head><meta name="test"/><title>A &amp; B</title></head><body>body<script src="/app.js"></script></body></html>'),
    asynchronous('request/route-hit-1000', () => route('/_api/item-999'), '<!DOCTYPE html><p>route</p>'),
    asynchronous('request/route-miss-1000', () => route('/missing'), '<!DOCTYPE html>fallback'),
  ];
}

export async function verifyCase(benchmark) {
  assert.deepEqual(await benchmark.run(), benchmark.expected, benchmark.name);
}
