import path from "path";
import fs from "fs";
import fg from "fast-glob";
import chokidar from "chokidar";

const defaultStaticAssetRoutesConfig = Object.freeze({
  headers: Object.freeze({}),
});

export default function resXVitePlugin(options = {}) {
  const {
    generated = "src/__generated__",
    serverUri = "http://localhost:4444",
    resXClientLocation = "node_modules/rescript-x/src/ResXClient.js",
    staticAssetRoutes: staticAssetRoutesOptions = defaultStaticAssetRoutesConfig,
  } = options;

  const staticAssetRoutes = createStaticAssetRoutesConfig(
    staticAssetRoutesOptions
  );
  const assetDir = "assets";
  const publicDir = "public";
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
      writeIfChanged(
        getStaticAssetRoutesJsFileLoc(generated),
        getDummyStaticAssetRoutesFile(
          assetDir,
          publicDir,
          resXClientLocation,
          staticAssetRoutes
        )
      );
      const content = getAssetDirContent(assetDir);

      // TODO: Check if really needed
      content.forEach(c => {
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
            bypass: req => {
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
        // Watch static asset roots for add/remove changes in development mode.
        watcher = chokidar.watch([assetDir, publicDir], {
          persistent: true,
          ignoreInitial: true,
        });

        watcher.on("add", _ => {
          regenerate(this);
        });

        watcher.on("unlink", _ => {
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
      const contentResolved = content.map(c => path.resolve(assetDir, c));
      contentResolved.push(fs.realpathSync(resXClientLocation));

      Object.entries(bundle).forEach(([key, v]) => {
        if (v.facadeModuleId != null) {
          const moduleId = v.facadeModuleId.split("?")[0];
          const bundlePath = key;
          const importedCss = v.viteMetadata?.importedCss.values().next().value;

          if (importedCss != null) {
            map[moduleId] = importedCss.toString();
          } else {
            const importedAsset = v.viteMetadata?.importedAssets
              .values()
              .next().value;

            if (importedAsset != null) {
              map[moduleId] = importedAsset.toString();
            } else {
              map[moduleId] = bundlePath.toString();
            }
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

      const jsFileContent = `export const assets = ${JSON.stringify(
        transformed,
        null,
        2
      )}`;

      writeIfChanged(getAssetJsFileLoc(generated), jsFileContent);
      writeIfChanged(
        getStaticAssetRoutesJsFileLoc(generated),
        getBuildStaticAssetRoutesFile(
          transformed,
          publicDir,
          outDir,
          staticAssetRoutes
        )
      );
    },
  };
}

function getAssetDirContent(assetDir) {
  return getDirContent(assetDir);
}

function getPublicDirContent(publicDir) {
  return getDirContent(publicDir, {
    dot: true,
  });
}

function getDirContent(dir, options = {}) {
  const { dot = false } = options;
  const cwd = path.resolve(dir);

  if (!fs.existsSync(cwd)) {
    return [];
  }

  return fg.globSync(["**/*"], {
    dot,
    cwd,
  });
}

function getAssetJsFileLoc(generated) {
  return path.resolve(generated, "res-x-assets.js");
}

function getStaticAssetRoutesJsFileLoc(generated) {
  return path.resolve(generated, "res-x-static-routes.js");
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
  content += `\n\n@module("./res-x-static-routes.js") external staticAssetRoutes: Dict.t<Bun.routeHandlerObject> = "staticAssetRoutes"`;

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

  return text.join("\n");
}

function getDummyDevFile(assetDir, resXClientLocation) {
  const content = getAssetDirContent(assetDir);
  let text = [`// Generated by ResX, do not edit manually\n`];
  const mapped = Object.fromEntries(content.map(k => [k, k]));

  text.push(
    `export const assets = {\n  "resXClient_js": "/${resXClientLocation}",\n${content
      .map(c => {
        const [_, transformed] = toRescriptFieldName(c, mapped);
        return `  "${transformed}": "/assets/${c}"`;
      })
      .join(",\n")}\n}`
  );

  return text.join("\n");
}

function createStaticAssetRoutesConfig(staticAssetRoutes = {}) {
  if (
    staticAssetRoutes == null ||
    typeof staticAssetRoutes !== "object" ||
    Array.isArray(staticAssetRoutes)
  ) {
    throw new Error(
      "`staticAssetRoutes` must be an object when passed to resXVitePlugin."
    );
  }

  if (staticAssetRoutes.assets != null) {
    throw new Error(
      "`staticAssetRoutes.assets` is no longer supported. ResX now always generates exact static asset routes. If you need a different asset loading strategy, implement your own asset pipeline."
    );
  }

  const headers = staticAssetRoutes.headers || {};

  if (typeof headers !== "object" || Array.isArray(headers)) {
    throw new Error(
      "`staticAssetRoutes.headers` must be an object whose keys are route patterns and whose values are header maps."
    );
  }

  Object.entries(headers).forEach(([pattern, value]) => {
    if (typeof pattern !== "string") {
      throw new Error("`staticAssetRoutes.headers` keys must be strings.");
    }

    if (value == null || typeof value !== "object" || Array.isArray(value)) {
      throw new Error(
        `\`staticAssetRoutes.headers.${pattern}\` must be an object of header name/value pairs.`
      );
    }
  });

  return {
    headers,
  };
}

function getDummyStaticAssetRoutesFile(
  assetDir,
  publicDir,
  resXClientLocation,
  staticAssetRoutes
) {
  return getStaticAssetRoutesFileContent({
    exactEntries: buildStaticAssetRouteEntries({
      publicEntries: getPublicRouteEntries({
        baseDir: publicDir,
        fileDir: publicDir,
      }),
      assetEntries: getAssetDirContent(assetDir).map(assetPath => ({
        routePath: toRoutePath(path.join("assets", assetPath)),
        filePath: toBunFilePath(path.join(assetDir, assetPath)),
      })),
      exactEntries: [
        {
          routePath: toRoutePath(resXClientLocation),
          filePath: toBunFilePath(resXClientLocation),
        },
      ],
      headers: staticAssetRoutes.headers,
    }),
  });
}

function getBuildStaticAssetRoutesFile(
  assetMap,
  publicDir,
  outDir,
  staticAssetRoutes
) {
  return getStaticAssetRoutesFileContent({
    exactEntries: buildStaticAssetRouteEntries({
      publicEntries: getPublicRouteEntries({
        baseDir: publicDir,
        fileDir: outDir,
      }),
      assetEntries: Object.values(assetMap).map(assetUrl => ({
        routePath: assetUrl,
        filePath: toBunFilePath(
          path.join(outDir, assetUrl.replace(/^\//, ""))
        ),
      })),
      headers: staticAssetRoutes.headers,
    }),
  });
}

function buildStaticAssetRouteEntries({
  publicEntries,
  assetEntries,
  exactEntries = [],
  headers,
}) {
  return dedupeStaticAssetRouteEntries([
    ...publicEntries,
    ...exactEntries,
    ...assetEntries,
  ]).map(entry => ({
    ...entry,
    headers: getStaticAssetRouteHeaders(headers, entry.routePath),
  }));
}

function dedupeStaticAssetRouteEntries(entries) {
  const dedupedEntries = new Map();

  entries.forEach(entry => {
    dedupedEntries.set(entry.routePath, entry);
  });

  return Array.from(dedupedEntries.values());
}

function getPublicRouteEntries({ baseDir, fileDir }) {
  return getPublicDirContent(baseDir)
    .map(publicPath => ({
      routePath: toRoutePath(publicPath),
      filePath: toBunFilePath(path.join(fileDir, publicPath)),
    }));
}

function getStaticAssetRouteHeaders(headers, routePath) {
  let matchedHeaders = null;

  Object.entries(headers).forEach(([pattern, value]) => {
    if (matchesStaticAssetRoutePattern(pattern, routePath)) {
      matchedHeaders = value;
    }
  });

  return matchedHeaders;
}

function matchesStaticAssetRoutePattern(pattern, routePath) {
  return matchStaticAssetRouteSegments(
    splitStaticAssetRoutePath(pattern),
    splitStaticAssetRoutePath(routePath)
  );
}

function matchStaticAssetRouteSegments(patternSegments, routeSegments) {
  if (patternSegments.length === 0) {
    return routeSegments.length === 0;
  }

  const [segment, ...restPatternSegments] = patternSegments;

  if (segment === "**") {
    if (restPatternSegments.length === 0) {
      return true;
    }

    for (let index = 0; index <= routeSegments.length; index++) {
      if (
        matchStaticAssetRouteSegments(
          restPatternSegments,
          routeSegments.slice(index)
        )
      ) {
        return true;
      }
    }

    return false;
  }

  if (routeSegments.length === 0) {
    return false;
  }

  if (segment === "*") {
    return matchStaticAssetRouteSegments(
      restPatternSegments,
      routeSegments.slice(1)
    );
  }

  if (segment !== routeSegments[0]) {
    return false;
  }

  return matchStaticAssetRouteSegments(
    restPatternSegments,
    routeSegments.slice(1)
  );
}

function splitStaticAssetRoutePath(routePath) {
  const normalized = toRoutePath(routePath);

  if (normalized === "/") {
    return [];
  }

  return normalized
    .slice(1)
    .split("/")
    .filter(segment => segment.length > 0);
}

function getStaticAssetRoutesFileContent({ exactEntries }) {
  const sharedHeaderNames = new Map();
  const headerDefinitions = [];
  let nextHeaderId = 0;

  const getHeaderName = headers => {
    if (headers == null) {
      return null;
    }

    const headerKey = JSON.stringify(headers);
    const existingHeaderName = sharedHeaderNames.get(headerKey);

    if (existingHeaderName != null) {
      return existingHeaderName;
    }

    const headerName = `staticAssetHeaders${nextHeaderId}`;
    nextHeaderId += 1;
    sharedHeaderNames.set(headerKey, headerName);
    headerDefinitions.push({
      name: headerName,
      value: headers,
    });
    return headerName;
  };

  const exactRoutes = exactEntries
    .sort((left, right) => left.routePath.localeCompare(right.routePath))
    .map(
      ({ routePath, filePath, headers }) => {
        const headerName = getHeaderName(headers);
        const responseOptions =
          headerName == null ? "" : `, { headers: ${headerName} }`;

        return `  ${JSON.stringify(routePath)}: {\n    GET: new Response(Bun.file(${JSON.stringify(
          filePath
        )})${responseOptions}),\n    HEAD: new Response(Bun.file(${JSON.stringify(
          filePath
        )})${responseOptions}),\n  }`;
      }
    );

  const headerConstants =
    headerDefinitions.length === 0
      ? ""
      : `${headerDefinitions
          .map(
            ({ name, value }) =>
              `const ${name} = ${JSON.stringify(value, null, 2)};`
          )
          .join("\n")}\n\n`;

  return `// Generated by ResX, do not edit manually

${headerConstants}export const staticAssetRoutes = {
${exactRoutes.join(",\n")}
}
`;
}

function normalizePath(filePath) {
  return filePath.replaceAll(path.sep, "/");
}

function toBunFilePath(filePath) {
  const normalized = normalizePath(filePath);
  return path.isAbsolute(filePath) ? normalized : "./" + normalized;
}

function toRoutePath(filePath) {
  return "/" + normalizePath(filePath).replace(/^\/+/, "");
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

export const __test = {
  createStaticAssetRoutesConfig,
  buildStaticAssetRouteEntries,
  getBuildStaticAssetRoutesFile,
  getDummyStaticAssetRoutesFile,
  getStaticAssetRouteHeaders,
  getStaticAssetRoutesFileContent,
  matchesStaticAssetRoutePattern,
};
