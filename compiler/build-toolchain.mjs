import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync, mkdirSync, existsSync, copyFileSync} from 'node:fs';
import {dirname, resolve, join} from 'node:path';
import {fileURLToPath} from 'node:url';

// Build in a private cache; never patch the supplied compiler checkout.
const here = dirname(fileURLToPath(import.meta.url));
const source = process.argv[2] || process.env.RESX_COMPILER_SOURCE;
if (!source) throw new Error('Usage: node compiler/build-toolchain.mjs /path/to/rescript-compiler (12.3.0; OCaml 5.3 + dune on PATH)');
const revision = execFileSync('git', ['-C', resolve(source), 'rev-parse', 'v12.3.0^{commit}'], {encoding: 'utf8'}).trim();
const pass = readFileSync(join(here, 'resx_templates.ml'));
const key = createHash('sha256').update(revision).update(pass).update('hook-v1').digest('hex').slice(0, 16);
const cache = join(here, '.toolchain', key);
const binary = join(cache, '_build/default/compiler/bsc/rescript_compiler_main.exe');
if (!existsSync(binary)) {
  mkdirSync(cache, {recursive: true});
  const archive = execFileSync('git', ['-C', resolve(source), 'archive', revision], {maxBuffer: 256 * 1024 * 1024});
  execFileSync('tar', ['-x', '-C', cache], {input: archive});
  copyFileSync(join(here, 'resx_templates.ml'), join(cache, 'compiler/core/resx_templates.ml'));
  const implementation = join(cache, 'compiler/core/js_implementation.ml');
  const original = readFileSync(implementation, 'utf8');
  const hook = 'let typedtree_coercion = (typedtree, coercion) in';
  if (original.split(hook).length !== 2) throw new Error('Unsupported compiler source: expected one typedtree hook');
  writeFileSync(implementation, original.replace(hook, 'let typedtree = Resx_templates.implementation typedtree in\n    ' + hook));
  execFileSync('dune', ['build', 'compiler/bsc/rescript_compiler_main.exe', '-j', '2'], {cwd: cache, stdio: ['inherit', 'inherit', 'inherit']});
}
writeFileSync(join(here, '.toolchain', 'binary'), binary + '\n');
console.log(binary);
