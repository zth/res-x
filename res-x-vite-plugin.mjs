import path from "path";
import fs from "fs";
import fg from "fast-glob";
import chokidar from "chokidar";

export default function resXVitePlugin(options = {}) {
  const {
    generated = "src/__generated__",
    serverUri = "http://localhost:4444",
    resXClientLocation = "node_modules/rescript-x/src/ResXClient.js",
  } = options;

  const assetDir = "assets";
  let outDir = "dist";
  let isBuild = false;
  let watcher;
  let indexContent = "";
  const virtualIndexId = "@res-x-index";

  function regenerate(context) {
    indexContent = getDummyFile(assetDir, resXClientLocation);
    writeResTypeFile(assetDir, generated);

    if (!isBuild) {
      const dummyDevFile = getDummyDevFile(assetDir, resXClientLocation);
      writeIfChanged(getAssetJsFileLoc(generated), dummyDevFile);
      const content = getAssetDirContent(assetDir);

      // TODO: Check if really needed
      content.forEach((c) => {
        context.load({
          id: path.resolve(c),
        });
      });
    }
  }

  return {
    name: "res-x-vite-plugin",

    configResolved(config) {
      options.outDir = config.build.outDir || outDir;
      outDir = options.outDir;

      isBuild = config.command === "build";

      config.css = config.css || {};
      config.css.codeSplit = false;
      config.css.extract = true;

      config.build.assetsInlineLimit = 0;
      config.build.rollupOptions.input = virtualIndexId;

      config.build.rollupOptions.preserveEntrySignatures = "strict";

      config.build.rollupOptions.output =
        config.build.rollupOptions.output || {};

      config.build.rollupOptions.output.preserveModules = true;

      if (config.command === "serve") {
        config.server = config.server || {};
        config.server.proxy = config.server.proxy || {};
        const proxy = config.server.proxy;
        if (proxy["/"] != null) {
          console.warn("[WARN] Path `/` is already proxied. Skipping.");
        } else {
          proxy["/"] = {
            target: serverUri,
            changeOrigin: true,
            bypass: (req) => {
              if (
                req.url?.startsWith("/assets/") ||
                req.url?.includes("@vite/client") ||
                req.url?.includes("node_modules/")
              ) {
                return req.url;
              }
              return null;
            },
          };
        }
      }
    },

    resolveId(id) {
      if (id === virtualIndexId) {
        return virtualIndexId;
      }
    },

    load(id) {
      if (id === virtualIndexId) {
        return indexContent;
      }
    },

    buildStart() {
      regenerate(this);

      if (!isBuild) {
        // Watch the asset directory for changes in development mode
        watcher = chokidar.watch(assetDir, {
          persistent: true,
          ignoreInitial: true,
        });

        watcher.on("add", (_) => {
          regenerate(this);
        });

        watcher.on("unlink", (_) => {
          regenerate(this);
        });
      }
    },

    buildEnd() {
      if (watcher) {
        watcher.close();
      }
    },

    closeBundle() {
      if (watcher) {
        watcher.close();
      }
    },

    generateBundle(_options, bundle) {
      const map = {};

      const content = getAssetDirContent(assetDir);
      const contentResolved = content.map((c) => path.resolve(assetDir, c));
      contentResolved.push(fs.realpathSync(resXClientLocation));

      Object.entries(bundle).forEach(([key, v]) => {
        if (v.facadeModuleId != null) {
          const moduleId = v.facadeModuleId.split("?")[0];
          const path = key;
          const importedAsset = v.viteMetadata?.importedAssets
            .values()
            .next().value;

          const importedCss = v.viteMetadata?.importedCss.values().next().value;

          if (importedAsset != null) {
            map[moduleId] = importedAsset.toString();
          } else if (importedCss != null) {
            map[moduleId] = importedCss.toString();
          } else {
            map[moduleId] = path.toString();
          }
        }
      });

      const transformed = contentResolved.reduce((acc, curr) => {
        const generated = map[curr];
        if (generated != null) {
          const adjustedKeyName = curr.endsWith("ResXClient.js")
            ? "resXClient.js"
            : path.relative(path.resolve(assetDir), curr);

          const [_, transformed] = toRescriptFieldName(adjustedKeyName, acc);

          acc[transformed] = "/" + generated;
        }
        return acc;
      }, {});

      // TODO: Fix cleanup?
      // Do some basic cleanup of assets Vite emits that we're not really interested in.
      /*Object.keys(bundle).forEach((key) => {
        const entry = bundle[key];
        if (
          key.includes("/_virtual/@res-x-index-") ||
          (key.endsWith(".js") && original[entry.name] != null)
        ) {
          delete bundle[key];
        }
      });*/

      // Write JS file
      const jsFileContent = `export const assets = ${JSON.stringify(
        transformed,
        null,
        2
      )}`;

      writeIfChanged(getAssetJsFileLoc(generated), jsFileContent);
    },
  };
}

function getAssetDirContent(assetDir) {
  return fg.globSync(["**/*"], {
    dot: false,
    cwd: path.resolve(assetDir),
  });
}

function getAssetJsFileLoc(generated) {
  return path.resolve(generated, "res-x-assets.js");
}

function getAssetResFileLoc(generated) {
  return path.resolve(generated, "ResXAssets.res");
}

function getManifestStructure(assetDir, map = null) {
  const content = getAssetDirContent(assetDir);
  return content.reduce((acc, curr) => {
    const generated = map != null ? map[curr] : curr;
    if (generated != null) {
      const [_, transformed] = toRescriptFieldName(curr, acc);
      acc[transformed] = generated;
    }
    return acc;
  }, {});
}

function writeIfChanged(p, content) {
  let currentContent = "";

  try {
    currentContent = fs.readFileSync(p, "utf8");
  } catch {}

  if (currentContent !== content) {
    const dir = path.dirname(p);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(p, content);
  }
}

function writeResTypeFile(assetDir, generated) {
  const mapped = getManifestStructure(assetDir);
  let content = `// Generated by ResX, do not edit manually\n\n`;

  content += `type assets = {\n  /** ResX Client Bundle */\n  resXClient_js: string,\n\n${Object.entries(
    mapped
  )
    .map(
      ([k, v], index) =>
        `${index > 0 ? "\n" : ""}  /** \`${v}\` */\n  ${k}: string,`
    )
    .join("\n")}\n}\n\n`;

  content += `@module("./res-x-assets.js") external assets: assets = "assets"`;

  const assetResFileLoc = getAssetResFileLoc(generated);
  writeIfChanged(assetResFileLoc, content);
}

function getDummyFile(assetDir, resXClientLocation) {
  const content = getAssetDirContent(assetDir);
  let text = [`// Generated by ResX, do not edit manually\n`];
  content.forEach((c, i) => {
    if (c.endsWith(".js")) return;
    text.push(`import v${i} from "${path.resolve(assetDir, c)}"`);
  });
  text.push(`import "${path.resolve(resXClientLocation)}"`);
  text.push(
    `\nexport const assets = {\n${content
      .map((c, i) => `  "${c}": v${i}`)
      .join(",\n")}\n}`
  );

  const txt = text.join("\n");
  return txt;
}

function getDummyDevFile(assetDir, resXClientLocation) {
  const content = getAssetDirContent(assetDir);
  let text = [`// Generated by ResX, do not edit manually\n`];
  const mapped = Object.fromEntries(content.map((k) => [k, k]));

  text.push(
    `export const assets = {\n  "resXClient_js": "/${resXClientLocation}",\n${content
      .map((c) => {
        const [_, transformed] = toRescriptFieldName(c, mapped);
        return `  "${transformed}": "/assets/${c}"`;
      })
      .join(",\n")}\n}`
  );

  const txt = text.join("\n");
  return txt;
}

function toRescriptFieldName(fieldName, existingObj) {
  let transformedFieldName = fieldName
    .replace(/\//g, "__")
    .replace(/[^a-zA-Z0-9_]/g, "_");

  if (!/[a-z]/g.test(transformedFieldName[0])) {
    transformedFieldName = `a${transformedFieldName}`;
  }

  while (typeof existingObj[transformedFieldName] === "string") {
    transformedFieldName += "_";
  }

  return [fieldName, transformedFieldName];
}
