import {spawn} from 'node:child_process';
import {createHash} from 'node:crypto';
import {createRequire} from 'node:module';
import {readFile, writeFile, mkdir, rename} from 'node:fs/promises';
import {readFileSync, realpathSync} from 'node:fs';
import {dirname, join, relative, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createInterface} from 'node:readline';
import MagicString from 'magic-string';

const here = dirname(fileURLToPath(import.meta.url));
export function createResxTransform({binary = process.env.RESX_OXC || join(here, 'oxc/target/release/resx-oxc'), runtimePath = join(here, '../src/Hjsx.js'), cacheDir} = {}) {
  runtimePath = realpathSync(runtimePath);
  const version = createHash('sha256').update(readFileSync(binary)).update('adapter-v1').digest('hex');
  const pending = [];
  const memory = new Map();
  const stats = {transformed: 0, templates: 0, cacheHits: 0, nativeRequests: 0};
  let child;
  let failure;
  let closed = false;
  let temporarySerial = 0;
  function send(request) {
    if (closed) return Promise.reject(new Error('ResX transform is closed'));
    if (failure) return Promise.reject(failure);
    if (!child) {
      child = spawn(binary, [], {stdio: ['pipe', 'pipe', 'inherit']});
      const fail = error => { failure = error; while (pending.length) pending.shift().reject(error); };
      child.on('error', fail);
      child.on('exit', code => { if (!closed || pending.length) fail(new Error(`ResX native transform exited: ${code}`)); });
      child.stdin.on('error', fail);
      createInterface({input: child.stdout}).on('line', line => {
        const item = pending.shift();
        if (!item) return fail(new Error('Unexpected native transform response'));
        try { const result = JSON.parse(line); if (result.error) throw new Error(result.error); item.resolve(result); }
        catch (error) { item.reject(error); }
        if (!pending.length) { child.unref(); child.stdout.unref?.(); child.stdin.unref?.(); }
      });
    }
    stats.nativeRequests++;
    return new Promise((resolve, reject) => {
      child.ref(); child.stdout.ref?.(); child.stdin.ref?.();
      pending.push({resolve, reject});
      child.stdin.write(JSON.stringify(request) + '\n');
    });
  }
  function specifiers(filename) {
    let local = relative(dirname(filename), runtimePath).split('\\').join('/');
    if (!local.startsWith('.')) local = './' + local;
    const result = [local, runtimePath];
    try {
      if (realpathSync(createRequire(filename).resolve('rescript-x/src/Hjsx.js')) === runtimePath) result.push('rescript-x/src/Hjsx.js');
    } catch (error) { if (error.code !== 'MODULE_NOT_FOUND') throw error; }
    return result;
  }
  return {
    stats,
    async transform(code, filename) {
      filename = resolve(filename);
      if (!code.includes('.Elements.')) return null;
      const runtimeSpecifiers = specifiers(filename);
      if (!runtimeSpecifiers.some(specifier => code.includes(specifier))) return null;
      const key = createHash('sha256').update(version).update(filename).update(JSON.stringify(runtimeSpecifiers)).update(code).digest('hex');
      if (memory.has(key)) { stats.cacheHits++; return memory.get(key); }
      const cacheFile = cacheDir && join(cacheDir, key + '.json');
      if (cacheFile) {
        try { const result = JSON.parse(await readFile(cacheFile, 'utf8')); memory.set(key, result); stats.cacheHits++; return result; }
        catch (error) { if (error.code !== 'ENOENT' && !(error instanceof SyntaxError)) throw error; }
      }
      const plan = await send({code, filename, runtimeSpecifiers});
      let result = null;
      if (plan.templates) {
        const output = new MagicString(code);
        for (const edit of plan.edits) output.overwrite(edit.start, edit.end, edit.text);
        output.append(plan.suffix);
        result = {code: output.toString(), map: output.generateMap({source: filename, includeContent: true, hires: true}).toString(), templates: plan.templates};
        stats.transformed++; stats.templates += plan.templates;
      }
      memory.set(key, result);
      if (cacheFile) {
        await mkdir(cacheDir, {recursive: true});
        const temporary = cacheFile + '.' + process.pid + '.' + temporarySerial++ + '.tmp';
        await writeFile(temporary, JSON.stringify(result));
        await rename(temporary, cacheFile);
      }
      return result;
    },
    close() { closed = true; if (child) child.stdin.end(); },
  };
}

// Conventional transform(code, id) adapter for Vite/Rollup-compatible pipelines.
export function resxOxcPlugin(options) {
  let transform;
  return {
    name: 'resx-oxc', enforce: 'pre',
    buildStart() { transform = createResxTransform(options); },
    async transform(code, id) {
      if (!/\.[cm]?js$/.test(id)) return null;
      return transform.transform(code, id);
    },
    closeBundle() { transform?.close(); },
  };
}
