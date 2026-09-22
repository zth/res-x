import assert from 'node:assert/strict';
import {execFileSync, spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const demo = fileURLToPath(new URL('../demo', import.meta.url));
async function capture(baseline) {
  execFileSync(process.execPath, ['../compiler/build.mjs', ...(baseline ? ['--baseline'] : [])], {cwd: demo, stdio: 'inherit'});
  const cwd = baseline ? demo : fileURLToPath(new URL('../demo/.resx/build', import.meta.url));
  const server = spawn('bun', ['run', 'src/Demo.js'], {cwd, env: {...process.env, PORT: '0', NODE_ENV: 'production'}, stdio: ['ignore', 'pipe', 'inherit']});
  try {
    const port = await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Demo did not start')), 15000);
      let output = '';
      const cleanup = () => clearTimeout(timer);
      server.on('error', error => { cleanup(); reject(error); });
      server.on('exit', code => { cleanup(); reject(new Error(`Demo exited: ${code}`)); });
      server.stdout.on('data', chunk => {
        output += chunk;
        const match = output.match(/Listening! on localhost:(\d+)/);
        if (match) { cleanup(); resolve(match[1]); }
      });
    });
    const results = [];
    for (const [path, status] of [['/catalog', 200], ['/start', 200], ['/not-a-route', 404]]) {
      const response = await fetch(`http://127.0.0.1:${port}${path}`, {signal: AbortSignal.timeout(10000)});
      assert.equal(response.status, status);
      const html = await response.text();
      assert(html.startsWith('<!DOCTYPE html>'));
      if (path === '/catalog') {
        assert(html.includes('The reading room'));
        assert.equal((html.match(/<article /g) || []).length, 3);
      }
      results.push({path, status: response.status, contentType: response.headers.get('content-type'), html});
      if (path === '/catalog') {
        const stylesheet = html.match(/href="([^"]+\.css)"/)?.[1];
        assert(stylesheet, 'catalog must include its stylesheet');
        const asset = await fetch(`http://127.0.0.1:${port}${stylesheet}`, {signal: AbortSignal.timeout(10000)});
        assert.equal(asset.status, 200);
        results.push({path: stylesheet, css: await asset.text()});
      }
    }
    return results;
  } finally {
    server.kill();
  }
}
const baseline = await capture(true);
assert.deepEqual(await capture(false), baseline, 'demo HTTP output must match baseline exactly');
console.log('Demo catalog, start page, and 404 responses match byte for byte.');
