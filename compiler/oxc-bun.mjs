import {readFile} from 'node:fs/promises';
import {createResxTransform} from './oxc-transform.mjs';

export function createResxBunPlugin(options) {
  const transform = createResxTransform(options);
  return {
    transform,
    plugin: {
      name: 'resx-oxc',
      setup(build) {
        build.onLoad({filter: /\.[cm]?js$/}, async ({path}) => {
          const code = await readFile(path, 'utf8');
          const result = await transform.transform(code, path);
          if (!result) return {contents: code, loader: 'js'};
          return {contents: result.code + '\n//# sourceMappingURL=data:application/json;base64,' + Buffer.from(result.map).toString('base64'), loader: 'js'};
        });
      },
    },
  };
}
