import {readFile} from 'node:fs/promises';
import {createResxTransform} from './oxc-transform.mjs';

// A regular build plugin: the bundler owns each compiler worker's lifetime.
export function resxBunPlugin(options) {
  let stats;
  return {
    name: 'resx-oxc',
    get stats() { return stats; },
    setup(build) {
      const transform = createResxTransform(options);
      stats = transform.stats;
      build.onEnd(() => transform.close());
      build.onLoad({filter: /\.[cm]?js$/}, async ({path}) => {
        const code = await readFile(path, 'utf8');
        const result = await transform.transform(code, path);
        // Let later plugins and Bun's loader handle modules we don't change.
        if (!result) return undefined;
        return {contents: result.code + '\n//# sourceMappingURL=data:application/json;base64,' + Buffer.from(result.map).toString('base64'), loader: 'js'};
      });
    },
  };
}
