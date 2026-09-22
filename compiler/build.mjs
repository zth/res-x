import {execFileSync} from 'node:child_process';
import {readFileSync, writeFileSync, existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const baseline = process.argv.includes('--baseline');
const require = createRequire(join(process.cwd(), 'package.json'));
const cli = join(dirname(require.resolve('rescript/package.json')), 'cli/rescript.js');
const manifest = JSON.parse(readFileSync(require.resolve('rescript/package.json'), 'utf8'));
if (manifest.version !== '12.3.0') throw new Error('This prototype requires ReScript 12.3.0');
const binary = process.env.RESX_BSC || readFileSync(join(here, '.toolchain/binary'), 'utf8').trim();
const version = execFileSync(binary, ['-version'], {encoding: 'utf8'});
if (!version.includes('12.3.0')) throw new Error('Custom compiler must match ReScript 12.3.0');
const env = {...process.env, RESCRIPT_BSC_EXE: resolve(binary), RESX_HTML_COMPILER: baseline ? '0' : '1', RAYON_NUM_THREADS: process.env.RAYON_NUM_THREADS || '2'};
// ReScript does not track optimization environment variables as build inputs.
const stamp = join(process.cwd(), '.resx-compiler-mode');
const mode = createHash('sha256').update(readFileSync(binary)).update(baseline ? 'baseline' : 'templates').digest('hex');
if (!existsSync(stamp) || readFileSync(stamp, 'utf8') !== mode) {
  execFileSync(process.execPath, [cli, 'clean'], {env, stdio: 'inherit'});
}
execFileSync(process.execPath, [cli], {env, stdio: 'inherit'});
writeFileSync(stamp, mode);
