import {describe, test, expect} from 'bun:test';
import {h, Fragment, render, renderSync, createRaw, createContext, useContext} from '../src/vendor/hyperons.js';
import {make} from '../src/Handlers.js';

describe('renderer fast paths', () => {
  test('text leaves, arrays, primitives, raw HTML, fragments and void elements', async () => {
    // Construct a numeric child directly: h currently drops a direct zero child.
    const tree = [h('p', {children: '<>&"\''}), {type: 'p', props: {children: 0}},
      h('p', {children: false}), h('p', {}), h('p', {children: [null, true, 0, false, 1]}),
      h(Fragment, {children: ['a', [undefined, 'b']]}), createRaw('<b>raw</b>'),
      h('br', {}), h('div', {dangerouslySetInnerHTML: {__html: '<i>raw</i>'}, children: 'ignored'})];
    const expected = '<p>&lt;&gt;&amp;&quot;&#x27;</p><p>0</p><p></p><p></p><p>01</p>ab<b>raw</b><br/><div><i>raw</i></div>';
    expect(renderSync(tree)).toBe(expected);
    expect(await render(tree)).toBe(expected);
  });
  test('sparse arrays preserve holes and order', () => {
    const children = []; children[2] = 'a'; children[5] = 'b';
    expect(renderSync(children)).toBe('ab');
  });
  test('sibling and nested providers restore context for consumers', async () => {
    const ctx = createContext('default');
    const Consumer = () => h('b', {children: useContext(ctx)});
    const tree = [h(ctx.Provider, {value: 'outer', children: [h(Consumer, {}),
      h(ctx.Provider, {value: 'inner', children: h(Consumer, {})}), h(Consumer, {})]}), h(Consumer, {})];
    expect(renderSync(tree)).toBe('<b>outer</b><b>inner</b><b>outer</b><b>default</b>');
    expect(await render(tree)).toBe(renderSync(tree));
  });
  test('async subtrees settle out of order but HTML remains in order', async () => {
    let resolveFirst;
    const first = new Promise(resolve => {resolveFirst = resolve;});
    const output = render(h('main', {children: ['before', first, 'middle', Promise.resolve('second'), 'after']}));
    await Promise.resolve();
    resolveFirst(h('b', {children: Promise.resolve('first')}));
    expect(await output).toBe('<main>before<b>first</b>middlesecondafter</main>');
  });
  test('async providers retain captured context', async () => {
    const ctx = createContext('default');
    const Consumer = () => useContext(ctx);
    const tree = ['start', h(ctx.Provider, {value: 'A', children: Promise.resolve(h(Consumer, {}))}),
      h(ctx.Provider, {value: 'B', children: Promise.resolve(h(Consumer, {}))}), 'end'];
    expect(await render(tree)).toBe('startABend');
  });
  test('async trees are repeatable and synchronous rendering rejects them', async () => {
    const tree = ['a', Promise.resolve(h('p', {children: 'b'})), 'c'];
    expect(await render(tree)).toBe('a<p>b</p>c');
    expect(await render(tree)).toBe('a<p>b</p>c');
    expect(() => renderSync(tree)).toThrow('Tried to render async tree sync.');
  });
  test('promise rejection and component exceptions propagate', async () => {
    const error = new Error('expected failure');
    await expect(render(['before', Promise.reject(error)])).rejects.toBe(error);
    await expect(render(Promise.resolve(h(() => {throw error;}, {})))).rejects.toBe(error);
    expect(() => renderSync(h(() => {throw error;}, {}))).toThrow(error);
  });
  test('error boundary output does not contain internal chunk counts', async () => {
    const ctx = createContext(null, 'errorBoundary');
    const tree = h(ctx.Provider, {value: () => 'fallback', children: h(() => {throw new Error('fail');}, {})});
    expect(renderSync(tree)).toBe('fallback');
    expect(await render([tree, Promise.resolve('tail')])).toBe('fallbacktail');
  });
  test('stream callback handles synchronous and one async tail', async () => {
    const chunks = [];
    expect(await render(['before', Promise.resolve(h('b', {children: 'after'}))], c => chunks.push(c))).toBeUndefined();
    expect(chunks).toEqual(['before', '<b>after</b>']);
  });
});

describe('request context isolation', () => {
  test('concurrent requests keep context across awaits, components, and hooks', async () => {
    const handler = make(async request => ({id: new URL(request.url).pathname}));
    const seen = [];
    const responses = await Promise.all(Array.from({length: 32}, (_, i) => handler.handleRequest({
      request: new Request(`http://localhost/${i}`),
      render: async config => {
        await new Promise(resolve => setTimeout(resolve, i % 3));
        expect(handler.useContext()).toBe(config);
        return h(async () => {
          await Promise.resolve();
          return h('p', {children: handler.useContext().context.id});
        }, {});
      },
      onAfterBuildResponse: async ({context}) => {
        await Promise.resolve();
        expect(handler.useContext().context).toBe(context);
        seen.push(context.id);
      },
    }).then(r => r.text())));
    expect(responses).toEqual(Array.from({length: 32}, (_, i) => `<!DOCTYPE html><p>/${i}</p>`));
    expect(new Set(seen).size).toBe(32);
    expect(handler.useContext()).toBeUndefined();
  });
});

test('streaming retains sibling and nested async output in document order', async () => {
  let resolveFirst;
  const first = new Promise(resolve => {resolveFirst = resolve;});
  const chunks = [];
  const pending = render(['prefix', first, 'middle', Promise.resolve('second'), 'suffix'], c => chunks.push(c));
  expect(chunks).toEqual(['prefix']);
  resolveFirst(h('b', {children: ['nested', Promise.resolve('first')]}));
  await pending;
  expect(chunks.join('')).toBe('prefix<b>nestedfirst</b>middlesecondsuffix');
  expect(chunks.join('')).not.toContain('[object Object]');
});

test('route dictionaries preserve late registration, methods, and first-handler precedence', async () => {
  const handler = make(async () => null);
  const allow = async () => ({TAG: 'Allow', _0: undefined});
  const request = (path, method = 'GET') => handler.handleRequest({
    request: new Request(`http://localhost${path}`, {method}), render: async () => 'missing',
  }).then(r => r.text());
  expect(await request('/_api/late')).toBe('<!DOCTYPE html>missing');
  handler.hxGet('/late', allow, async () => 'late', false);
  expect(await request('/_api/late')).toBe('<!DOCTYPE html>late');
  for (let i = 0; i < 128; i++) {
    handler.hxGet(`/route-${i}`, allow, async () => `get-${i}`, false);
    handler.hxPost(`/route-${i}`, allow, async () => `post-${i}`, false);
  }
  for (const i of [0, 1, 63, 64, 126, 127]) {
    expect(await request(`/_api/route-${i}`)).toBe(`<!DOCTYPE html>get-${i}`);
    expect(await request(`/_api/route-${i}`, 'POST')).toBe(`<!DOCTYPE html>post-${i}`);
    expect(await request(`/_api/route-${i}`, 'PUT')).toBe('<!DOCTYPE html>missing');
  }
  for (const name of ['__proto__', 'constructor', 'toString']) {
    handler.hxGet(`/${name}`, allow, async () => name, false);
    expect(await request(`/_api/${name}`)).toBe(`<!DOCTYPE html>${name}`);
  }
});

test('request context is restored after a rejected render', async () => {
  const handler = make(async () => 'context');
  await expect(handler.handleRequest({
    request: new Request('http://localhost/fail'),
    render: async () => {await Promise.resolve(); throw new Error('render failed');},
  })).rejects.toThrow('render failed');
  expect(handler.useContext()).toBeUndefined();
  const response = await handler.handleRequest({
    request: new Request('http://localhost/ok'), render: async () => handler.useContext().context,
  });
  expect(await response.text()).toBe('<!DOCTYPE html>context');
});
