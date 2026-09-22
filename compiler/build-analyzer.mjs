import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {writeFileSync, mkdirSync, existsSync, copyFileSync} from 'node:fs';
import {dirname, resolve, join} from 'node:path';
import {fileURLToPath} from 'node:url';

// Link a separate CMT reader against unmodified compiler libraries. No bsc is built or patched.
const here = dirname(fileURLToPath(import.meta.url));
const source = process.argv[2] || process.env.RESX_COMPILER_SOURCE;
if (!source) throw new Error('Usage: node compiler/build-analyzer.mjs /path/to/rescript-compiler (12.3.0; OCaml 5.3 + dune on PATH)');
const revision = execFileSync('git', ['-C', resolve(source), 'rev-parse', 'v12.3.0^{commit}'], {encoding: 'utf8'}).trim();
const key = createHash('sha256').update(revision).update('standalone-v2').digest('hex').slice(0, 16);
const cache = join(here, '.toolchain', key);
const binary = join(cache, '_build/default/compiler/ml/resx/resx_templates.exe');
if (!existsSync(join(cache, 'dune-project'))) {
  mkdirSync(cache, {recursive: true});
  const archive = execFileSync('git', ['-C', resolve(source), 'archive', revision], {maxBuffer: 256 * 1024 * 1024});
  execFileSync('tar', ['-x', '-C', cache], {input: archive});
}
mkdirSync(join(cache, 'compiler/ml/resx'), {recursive: true});
copyFileSync(join(here, 'resx_templates.ml'), join(cache, 'compiler/ml/resx/resx_templates.ml'));
copyFileSync(join(here, 'dune'), join(cache, 'compiler/ml/resx/dune'));
execFileSync('dune', ['build', 'compiler/ml/resx/resx_templates.exe', '-j', '2'], {cwd: cache, stdio: 'inherit'});
writeFileSync(join(here, '.toolchain', 'analyzer'), binary + '\n');
console.log(binary);
