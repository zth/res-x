import {execFileSync} from 'node:child_process';
import {readFileSync, writeFileSync, existsSync, mkdirSync, rmSync, readdirSync, cpSync, symlinkSync} from 'node:fs';
import {dirname, join, resolve, relative, basename} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const root = process.cwd();
const baseline = process.argv.includes('--baseline');
const require = createRequire(join(root, 'package.json'));
const rescript = dirname(require.resolve('rescript/package.json'));
const cli = join(rescript, 'cli/rescript.js');
if (JSON.parse(readFileSync(join(rescript, 'package.json'), 'utf8')).version !== '12.3.0') {
  throw new Error('This prototype reads ReScript 12.3.0 CMT artifacts');
}
const env = {...process.env, RAYON_NUM_THREADS: process.env.RAYON_NUM_THREADS || '2'};
// Both compilation stages always use the stock npm compiler.
delete env.RESCRIPT_BSC_EXE;
delete env.RESX_HTML_COMPILER;
const times = {};
function timed(name, fn) {
  const start = performance.now();
  const result = fn();
  times[name] = performance.now() - start;
  return result;
}
function compile(cwd) { execFileSync(process.execPath, [cli], {cwd, env, stdio: 'inherit'}); }
timed('stockCompileMs', () => compile(root));
if (baseline) {
  console.log(JSON.stringify({mode: 'baseline', ...times}));
  process.exit(0);
}
const analyzer = process.env.RESX_ANALYZER || readFileSync(join(here, '.toolchain/analyzer'), 'utf8').trim();
const output = join(root, '.resx/build');
const config = JSON.parse(readFileSync(join(root, 'rescript.json'), 'utf8'));
if (config.jsx?.module !== 'Hjsx') throw new Error('Prototype requires jsx.module = Hjsx');
const inputs = [];
function sources(entries, parent = root) {
  for (const entry of Array.isArray(entries) ? entries : [entries]) {
    const item = typeof entry === 'string' ? {dir: entry} : entry;
    const directory = resolve(parent, item.dir);
    if (!relative(root, directory) || relative(root, directory).startsWith('..')) throw new Error('Prototype requires source directories inside the project');
    for (const file of readdirSync(directory, {withFileTypes: true})) {
      if (file.isFile() && file.name.endsWith('.res')) inputs.push(join(directory, file.name));
      if (file.isDirectory() && item.subdirs === true) sources({dir: file.name, subdirs: true}, directory);
    }
    if (Array.isArray(item.subdirs)) sources(item.subdirs, directory);
  }
}
sources(config.sources);
// Keep the source application and its emitted JS intact. The generated project
// includes local JS/FFI/assets so relative imports retain their meaning.
timed('stageMs', () => {
  rmSync(output, {recursive: true, force: true});
  mkdirSync(output, {recursive: true});
  const excluded = new Set(['.git', '.resx', 'node_modules', 'lib', 'compiler']);
  for (const entry of readdirSync(root)) {
    if (excluded.has(entry)) continue;
    cpSync(join(root, entry), join(output, entry), {recursive: true,
      filter: path => !relative(root, path).split('/').some(part => excluded.has(part))});
  }
  symlinkSync(join(root, 'node_modules'), join(output, 'node_modules'), 'dir');
});
const artifacts = readdirSync(join(root, 'lib/ocaml'));
let templates = 0;
timed('analysisMs', () => {
  for (const input of inputs) {
    const stem = basename(input, '.res');
    const matches = artifacts.filter(name => name === `${stem}.cmt` || name.startsWith(`${stem}-`) && name.endsWith('.cmt'));
    if (matches.length !== 1) throw new Error(`Expected one CMT for ${input}, found ${matches.length}`);
    const result = execFileSync(analyzer, [join(root, 'lib/ocaml', matches[0]), input, join(output, relative(root, input))], {encoding: 'utf8'});
    templates += Number(result.trim());
  }
});
timed('generatedCompileMs', () => compile(output));
const report = {mode: 'standalone', output, modules: inputs.length, templates, ...times};
writeFileSync(join(root, '.resx/build-report.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify(report));
