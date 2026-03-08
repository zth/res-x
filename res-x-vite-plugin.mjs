import path from "path";
import fs from "fs";
import crypto from "crypto";
import fg from "fast-glob";

const defaultClientEntryExtensions = [".js", ".mjs", ".jsx", ".ts", ".tsx"];
const defaultExtraClientEntries = {
  resXClient_js: "node_modules/rescript-x/src/ResXClient.js",
};
const assetInputPrefix = "__resx_asset__";
const assetVirtualModulePrefix = "@res-x-asset-entry:";
const clientInputPrefix = "__resx_client__";

const defaultStaticAssetRoutesConfig = Object.freeze({
  headers: Object.freeze({}),
});

export default function resXVitePlugin(options = {}) {
  const {
    generated = "src/__generated__",
    serverUri = "http://localhost:4444",
    resXClientLocation = defaultExtraClientEntries.resXClient_js,
    staticAssetRoutes: staticAssetRoutesOptions = defaultStaticAssetRoutesConfig,
    assetDir = "assets",
    clientDirs = [],
    clientEntryExtensions = defaultClientEntryExtensions,
    assetEntryGlobs = getDefaultEntryGlobs(clientEntryExtensions),
    clientEntryGlobs = getDefaultEntryGlobs(clientEntryExtensions),
    extraClientEntries = {},
    devOrigin,
  } = options;

  const staticAssetRoutes = createStaticAssetRoutesConfig(
    staticAssetRoutesOptions
  );
  const publicDir = "public";
  const resolvedExtraClientEntries = {
    ...defaultExtraClientEntries,
    ...(resXClientLocation == null ? {} : { resXClient_js: resXClientLocation }),
    ...extraClientEntries,
  };

  let projectRoot = process.cwd();
  let outDir = "dist";
  let isBuild = false;
  let stopWatching = null;
  let manifest = [];
  let resolvedDevOrigin = normalizeDevOrigin("http://localhost:9000");

  function regenerate(context) {
    manifest = getManifest({
      assetDir,
      assetEntryGlobs,
      clientDirs,
      clientEntryExtensions,
      clientEntryGlobs,
      extraClientEntries: resolvedExtraClientEntries,
      projectRoot,
    });
    writeResTypeFile(projectRoot, generated, manifest);

    if (!isBuild) {
      writeIfChanged(
        getAssetJsFileLoc(projectRoot, generated),
        getGeneratedDevAssetMap(manifest, resolvedDevOrigin)
      );
      writeIfChanged(
        getStaticAssetRoutesJsFileLoc(projectRoot, generated),
        getDummyStaticAssetRoutesFile(
          assetDir,
          publicDir,
          resolvedExtraClientEntries.resXClient_js,
          staticAssetRoutes
        )
      );

      manifest.forEach(entry => {
        context.addWatchFile(entry.sourcePath);
      });
    }
  }

  return {
    name: "res-x-vite-plugin",

    config(config, env) {
      const configProjectRoot = getProjectRoot(config.root);
      const configManifest = getManifest({
        assetDir,
        assetEntryGlobs,
        clientDirs,
        clientEntryExtensions,
        clientEntryGlobs,
        extraClientEntries: resolvedExtraClientEntries,
        projectRoot: configProjectRoot,
      });
      const buildInputs = getBuildInputs(configManifest);
      const existingInputs = normalizeRollupInput(
        config.build?.rollupOptions?.input
      );
      const nextConfig = {
        css: {
          ...(config.css || {}),
          codeSplit: false,
          extract: true,
        },
        build: {
          assetsInlineLimit: 0,
          rollupOptions: {
            input: {
              ...existingInputs,
              ...buildInputs,
            },
            preserveEntrySignatures: "strict",
            output: {
              assetFileNames: assetInfo => {
                const parsedName = path.parse(assetInfo.name || "asset");
                return `assets/${stripOutputPrefix(parsedName.name)}-[hash][extname]`;
              },
              entryFileNames: chunkInfo => {
                return `assets/${stripOutputPrefix(chunkInfo.name)}-[hash].js`;
              },
            },
          },
        },
      };

      if (env.command === "serve") {
        const proxy = config.server?.proxy || {};
        if (proxy["/"] != null) {
          console.warn("[WARN] Path `/` is already proxied. Skipping.");
        } else {
          nextConfig.server = {
            proxy: {
              ...proxy,
              "/": {
                target: serverUri,
                changeOrigin: true,
                bypass: req => {
                  const requestPath = stripUrlSearchHash(req.url);
                  if (
                    requestPath?.startsWith(`/${stripLeadingSlash(assetDir)}/`) ||
                    requestPath?.includes("@vite/client") ||
                    requestPath?.includes("node_modules/") ||
                    requestPath?.startsWith("/@fs/") ||
                    getProjectFileForRequest(configProjectRoot, requestPath) !=
                      null
                  ) {
                    return req.url;
                  }

                  return null;
                },
              },
            },
          };
        }
      }

      return nextConfig;
    },

    configResolved(config) {
      projectRoot = config.root;
      outDir = config.build.outDir || outDir;
      isBuild = config.command === "build";
      resolvedDevOrigin = getResolvedDevOrigin(config, devOrigin);
      manifest = getManifest({
        assetDir,
        assetEntryGlobs,
        clientDirs,
        clientEntryExtensions,
        clientEntryGlobs,
        extraClientEntries: resolvedExtraClientEntries,
        projectRoot,
      });
    },

    resolveId(id) {
      if (isAssetVirtualModuleId(id)) {
        return id;
      }
    },

    load(id) {
      const assetEntry = manifest.find(
        entry => entry.kind === "asset" && entry.buildId === id
      );
      if (assetEntry != null) {
        return getAssetEntryModule(assetEntry);
      }
    },

    configureServer(server) {
      const watchPaths = getWatchPaths({
        assetDir,
        publicDir,
        clientDirs,
        extraClientEntries: resolvedExtraClientEntries,
        projectRoot,
      });
      const handleRegenerate = () => {
        regenerate({
          addWatchFile: filePath => {
            server.watcher.add(filePath);
          },
        });
        server.ws.send({ type: "full-reload" });
      };

      server.watcher.add(watchPaths);
      ["add", "change", "unlink"].forEach(eventName => {
        server.watcher.on(eventName, handleRegenerate);
      });

      stopWatching = () => {
        ["add", "change", "unlink"].forEach(eventName => {
          server.watcher.off(eventName, handleRegenerate);
        });
      };
    },

    buildStart() {
      regenerate(this);
    },

    buildEnd() {
      closeWatcher(stopWatching);
    },

    closeBundle() {
      closeWatcher(stopWatching);
    },

    generateBundle(_options, bundle) {
      const assetEntriesByBuildId = new Map(
        manifest
          .filter(entry => entry.kind === "asset")
          .map(entry => [entry.buildId, entry])
      );
      const clientEntriesByLookupId = new Map();
      manifest
        .filter(entry => entry.kind === "client")
        .forEach(entry => {
          entry.buildLookupIds.forEach(lookupId => {
            clientEntriesByLookupId.set(lookupId, entry);
          });
        });

      const assetFileNameByBuildId = new Map();
      const clientFileNameByFieldName = new Map();
      const assetWrapperChunkFileNames = [];

      Object.entries(bundle).forEach(([fileName, output]) => {
        if (output.type !== "chunk" || output.facadeModuleId == null) {
          return;
        }

        const facadeModuleId = stripQuery(output.facadeModuleId);
        const assetEntry = assetEntriesByBuildId.get(facadeModuleId);
        if (assetEntry != null) {
          assetFileNameByBuildId.set(
            assetEntry.buildId,
            getTransformedAssetFileName(output)
          );
          assetWrapperChunkFileNames.push(fileName);
          return;
        }

        const clientEntry = clientEntriesByLookupId.get(facadeModuleId);
        if (clientEntry != null) {
          const importedCss = Array.from(
            output.viteMetadata?.importedCss || []
          ).map(fileName => normalizeEmittedFileName(fileName.toString()));
          const wrapperFileName = getClientEntryWrapperFileName(
            clientEntry.fieldName,
            output.fileName,
            importedCss
          );

          bundle[wrapperFileName] = {
            fileName: wrapperFileName,
            source: getClientEntryWrapperModule(
              wrapperFileName,
              output.fileName,
              importedCss
            ),
            type: "asset",
          };

          clientFileNameByFieldName.set(clientEntry.fieldName, wrapperFileName);
        }
      });

      const assets = manifest.reduce((acc, entry) => {
        const generatedPath =
          entry.kind === "asset"
            ? assetFileNameByBuildId.get(entry.buildId)
            : clientFileNameByFieldName.get(entry.fieldName);

        if (generatedPath != null) {
          acc[entry.fieldName] = `/${generatedPath}`;
        }

        return acc;
      }, {});

      assetWrapperChunkFileNames.forEach(fileName => {
        delete bundle[fileName];
      });

      const bundleFileNames = Object.values(bundle)
        .map(output => output.fileName)
        .filter(Boolean);

      writeIfChanged(
        getAssetJsFileLoc(projectRoot, generated),
        getGeneratedAssetModule(assets)
      );
      writeIfChanged(
        getStaticAssetRoutesJsFileLoc(projectRoot, generated),
        getBuildStaticAssetRoutesFile({
          bundleFileNames,
          outDir,
          publicDir,
          staticAssetRoutes,
        })
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

function getDirContent(dirPath, options = {}) {
  const { dot = false } = options;
  const cwd = path.resolve(dirPath);

  if (!fs.existsSync(cwd)) {
    return [];
  }

  return fg
    .globSync(["**/*"], {
      cwd,
      dot,
      onlyFiles: true,
    })
    .sort();
}

function getDirContentMatchingPatterns(dirPath, patterns) {
  if (!fs.existsSync(dirPath) || patterns.length === 0) {
    return [];
  }

  return fg
    .globSync(patterns, {
      cwd: dirPath,
      dot: false,
      onlyFiles: true,
    })
    .sort();
}

function getManifest({
  assetDir,
  assetEntryGlobs,
  clientDirs,
  clientEntryExtensions,
  clientEntryGlobs,
  extraClientEntries,
  projectRoot,
}) {
  const entries = [];
  const usedFieldNames = {};

  Object.entries(extraClientEntries).forEach(([fieldName, sourcePath]) => {
    validateExplicitFieldName(fieldName);

    if (usedFieldNames[fieldName] != null) {
      throw new Error(`Duplicate ResX asset field name: ${fieldName}`);
    }

    const absoluteSourcePath = resolveConfiguredPath(projectRoot, sourcePath);
    if (!fs.existsSync(absoluteSourcePath)) {
      throw new Error(
        `Configured ResX client entry is missing: ${sourcePath} (${fieldName})`
      );
    }

    usedFieldNames[fieldName] = sourcePath;
    entries.push(
      createManifestEntry({
        buildId: normalizeFsPath(absoluteSourcePath),
        buildLookupIds: getPathAliases(absoluteSourcePath),
        comment:
          fieldName === "resXClient_js"
            ? "ResX Client Bundle"
            : `\`${sourcePath}\``,
        displayPath: sourcePath,
        fieldName,
        inputName: `${clientInputPrefix}${fieldName}`,
        kind: "client",
        projectRoot,
        relativePath: sourcePath,
        sourcePath: absoluteSourcePath,
      })
    );
  });

  const resolvedAssetDir = resolveConfiguredPath(projectRoot, assetDir);
  const assetEntries = new Set(
    getDirContentMatchingPatterns(resolvedAssetDir, assetEntryGlobs)
  );

  getDirContent(resolvedAssetDir).forEach(relativePath => {
    const absoluteSourcePath = path.resolve(resolvedAssetDir, relativePath);
    const isClientLike = isClientEntryFile(relativePath, clientEntryExtensions);
    if (isClientLike && !assetEntries.has(relativePath)) {
      return;
    }

    const fieldName = toRescriptFieldName(relativePath, usedFieldNames);
    usedFieldNames[fieldName] = relativePath;
    const kind = isClientLike ? "client" : "asset";

    entries.push(
      createManifestEntry({
        buildId:
          kind === "asset"
            ? getAssetVirtualModuleId(fieldName)
            : normalizeFsPath(absoluteSourcePath),
        buildLookupIds:
          kind === "asset"
            ? [getAssetVirtualModuleId(fieldName)]
            : getPathAliases(absoluteSourcePath),
        comment: `\`${relativePath}\``,
        displayPath: relativePath,
        fieldName,
        inputName: `${kind === "asset" ? assetInputPrefix : clientInputPrefix}${fieldName}`,
        kind,
        projectRoot,
        relativePath,
        sourcePath: absoluteSourcePath,
      })
    );
  });

  clientDirs.forEach(clientDir => {
    const resolvedClientDir = resolveConfiguredPath(projectRoot, clientDir);
    const sourceRootLabel = getSourceRootLabel(
      projectRoot,
      clientDir,
      resolvedClientDir
    );

    getDirContentMatchingPatterns(resolvedClientDir, clientEntryGlobs).forEach(
      relativePath => {
        if (!isClientEntryFile(relativePath, clientEntryExtensions)) {
          return;
        }

        const absoluteSourcePath = path.resolve(resolvedClientDir, relativePath);
        const displayPath = toPosix(path.join(sourceRootLabel, relativePath));
        const fieldName = toRescriptFieldName(displayPath, usedFieldNames);
        usedFieldNames[fieldName] = displayPath;

        entries.push(
          createManifestEntry({
            buildId: normalizeFsPath(absoluteSourcePath),
            buildLookupIds: getPathAliases(absoluteSourcePath),
            comment: `\`${displayPath}\``,
            displayPath,
            fieldName,
            inputName: `${clientInputPrefix}${fieldName}`,
            kind: "client",
            projectRoot,
            relativePath,
            sourcePath: absoluteSourcePath,
          })
        );
      }
    );
  });

  return entries;
}

function createManifestEntry({
  buildId,
  buildLookupIds,
  comment,
  displayPath,
  fieldName,
  inputName,
  kind,
  projectRoot,
  relativePath,
  sourcePath,
}) {
  return {
    buildId,
    buildLookupIds,
    comment,
    displayPath,
    fieldName,
    inputName,
    kind,
    projectRelativePath: getProjectRelativePath(projectRoot, sourcePath),
    relativePath: toPosix(relativePath),
    sourcePath: normalizeFsPath(sourcePath),
  };
}

function getBuildInputs(manifest) {
  return manifest.reduce((acc, entry) => {
    acc[entry.inputName] = entry.buildId;
    return acc;
  }, {});
}

function getAssetEntryModule(entry) {
  const sourcePath = JSON.stringify(entry.sourcePath);
  const fieldName = JSON.stringify(entry.fieldName);

  if (isStylesheetFile(entry.sourcePath)) {
    return `import ${sourcePath};\nglobalThis.__resxAssetEntry = ${fieldName};`;
  }

  return `import assetUrl from ${sourcePath};\nglobalThis.__resxAssetEntry = assetUrl;`;
}

function getGeneratedAssetModule(assets) {
  return `export const assets = ${JSON.stringify(assets, null, 2)}`;
}

function getClientEntryWrapperModule(
  wrapperFileName,
  entryFileName,
  cssFileNames
) {
  const relativeEntryPath = toImportPath(wrapperFileName, entryFileName);
  const relativeCssPaths = cssFileNames.map(cssFileName =>
    toImportPath(wrapperFileName, cssFileName)
  );

  return `const d=document,c=${JSON.stringify(relativeCssPaths)};for(const p of c){const h=new URL(p,import.meta.url).href;if(d.querySelector(\`link[rel="stylesheet"][href="\${h}"]\`)==null){const l=d.createElement("link");l.rel="stylesheet";l.href=h;d.head.appendChild(l)}}import(${JSON.stringify(relativeEntryPath)});`;
}

function getGeneratedDevAssetMap(manifest, devOrigin) {
  const assets = manifest.reduce((acc, entry) => {
    acc[entry.fieldName] = getDevAssetUrl(entry, devOrigin);
    return acc;
  }, {});

  return getGeneratedAssetModule(assets);
}

function getDevAssetUrl(entry, devOrigin) {
  if (entry.projectRelativePath != null) {
    return `${devOrigin}/${stripLeadingSlash(entry.projectRelativePath)}`;
  }

  return `${devOrigin}/@fs${entry.sourcePath}`;
}

function getResolvedDevOrigin(config, explicitDevOrigin) {
  if (explicitDevOrigin != null) {
    return normalizeDevOrigin(explicitDevOrigin);
  }

  if (config.server.origin != null) {
    return normalizeDevOrigin(config.server.origin);
  }

  const protocol = config.server.https ? "https" : "http";
  const host = normalizeDevHost(config.server.host);
  const port = config.server.port || 5173;

  return normalizeDevOrigin(`${protocol}://${host}:${port}`);
}

function getTransformedAssetFileName(output) {
  const importedCss = output.viteMetadata?.importedCss.values().next().value;
  if (importedCss != null) {
    return normalizeEmittedFileName(importedCss.toString());
  }

  const importedAsset = output.viteMetadata?.importedAssets
    .values()
    .next().value;
  if (importedAsset != null) {
    return normalizeEmittedFileName(importedAsset.toString());
  }

  return normalizeEmittedFileName(output.fileName.toString());
}

function getClientEntryWrapperFileName(fieldName, entryFileName, cssFileNames) {
  const hash = crypto
    .createHash("sha256")
    .update(entryFileName)
    .update("\0")
    .update(cssFileNames.join("\0"))
    .digest("hex")
    .slice(0, 8);

  return path.posix.join("assets", `${fieldName}_loader-${hash}.js`);
}

function getWatchPaths({
  assetDir,
  publicDir,
  clientDirs,
  extraClientEntries,
  projectRoot,
}) {
  return [
    resolveConfiguredPath(projectRoot, assetDir),
    resolveConfiguredPath(projectRoot, publicDir),
    ...clientDirs.map(clientDir =>
      resolveConfiguredPath(projectRoot, clientDir)
    ),
    ...Object.values(extraClientEntries).map(sourcePath =>
      resolveConfiguredPath(projectRoot, sourcePath)
    ),
  ];
}

function closeWatcher(stopWatching) {
  if (stopWatching != null) {
    stopWatching();
  }
}

function writeResTypeFile(projectRoot, generated, manifest) {
  let content = `// Generated by ResX, do not edit manually\n\n`;

  content += `type assets = {\n${manifest
    .map(
      (entry, index) =>
        `${index > 0 ? "\n" : ""}  /** ${entry.comment} */\n  ${entry.fieldName}: string,`
    )
    .join("\n")}\n}\n\n`;

  content += `@module("./res-x-assets.js") external assets: assets = "assets"`;
  content += `\n\n@module("./res-x-static-routes.js") external staticAssetRoutes: Dict.t<Bun.routeHandlerObject> = "staticAssetRoutes"`;

  writeIfChanged(getAssetResFileLoc(projectRoot, generated), content);
}

function writeIfChanged(filePath, content) {
  let currentContent = "";

  try {
    currentContent = fs.readFileSync(filePath, "utf8");
  } catch {}

  if (currentContent !== content) {
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(filePath, content);
  }
}

function getAssetJsFileLoc(projectRoot, generated) {
  return path.resolve(projectRoot, generated, "res-x-assets.js");
}

function getStaticAssetRoutesJsFileLoc(projectRoot, generated) {
  return path.resolve(projectRoot, generated, "res-x-static-routes.js");
}

function getAssetResFileLoc(projectRoot, generated) {
  return path.resolve(projectRoot, generated, "ResXAssets.res");
}

function resolveConfiguredPath(projectRoot, configuredPath) {
  if (path.isAbsolute(configuredPath)) {
    return normalizeFsPath(configuredPath);
  }

  return normalizeFsPath(path.resolve(projectRoot, configuredPath));
}

function getProjectRoot(configRoot) {
  if (configRoot == null) {
    return process.cwd();
  }

  return path.resolve(configRoot);
}

function getProjectRelativePath(projectRoot, sourcePath) {
  const relativePath = path.relative(projectRoot, sourcePath);
  if (relativePath.startsWith("..")) {
    return null;
  }

  return toPosix(relativePath);
}

function getSourceRootLabel(projectRoot, configuredPath, resolvedPath) {
  if (!path.isAbsolute(configuredPath)) {
    return stripTrailingSlash(toPosix(configuredPath));
  }

  const projectRelativePath = getProjectRelativePath(projectRoot, resolvedPath);
  if (projectRelativePath != null) {
    return stripTrailingSlash(projectRelativePath);
  }

  return path.basename(resolvedPath);
}

function normalizeRollupInput(input) {
  if (input == null) {
    return {};
  }

  if (typeof input === "string") {
    return { app: input };
  }

  if (Array.isArray(input)) {
    return input.reduce((acc, current, index) => {
      acc[`app_${index}`] = current;
      return acc;
    }, {});
  }

  return input;
}

function getProjectFileForRequest(projectRoot, requestPath) {
  if (requestPath == null || !requestPath.startsWith("/")) {
    return null;
  }

  const resolvedPath = path.resolve(projectRoot, stripLeadingSlash(requestPath));
  const projectRootWithSep = `${normalizeFsPath(projectRoot)}${path.sep}`;

  if (
    resolvedPath !== normalizeFsPath(projectRoot) &&
    !resolvedPath.startsWith(projectRootWithSep)
  ) {
    return null;
  }

  try {
    const stat = fs.statSync(resolvedPath);
    return stat.isFile() ? resolvedPath : null;
  } catch {
    return null;
  }
}

function getPathAliases(filePath) {
  const aliases = new Set([normalizeFsPath(filePath)]);

  try {
    aliases.add(normalizeFsPath(fs.realpathSync(filePath)));
  } catch {}

  return Array.from(aliases);
}

function stripQuery(filePath) {
  const strippedPath = filePath.split("?")[0];
  if (isAssetVirtualModuleId(strippedPath)) {
    return strippedPath;
  }

  return normalizeFsPath(strippedPath);
}

function isClientEntryFile(filePath, clientEntryExtensions) {
  return clientEntryExtensions.includes(path.extname(filePath));
}

function isStylesheetFile(filePath) {
  return [
    ".css",
    ".less",
    ".pcss",
    ".postcss",
    ".sass",
    ".scss",
    ".styl",
    ".stylus",
  ].includes(path.extname(filePath));
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
  const assetRouteBase = path.basename(normalizeFsPath(assetDir));

  return getStaticAssetRoutesFileContent({
    exactEntries: buildStaticAssetRouteEntries({
      publicEntries: getPublicRouteEntries({
        baseDir: publicDir,
        fileDir: publicDir,
      }),
      assetEntries: getAssetDirContent(assetDir).map(assetPath => ({
        routePath: toRoutePath(path.join(assetRouteBase, assetPath)),
        filePath: toBunFilePath(path.join(assetDir, assetPath)),
      })),
      exactEntries:
        resXClientLocation == null
          ? []
          : [
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
  assetMapOrOptions,
  publicDirArg,
  outDirArg,
  staticAssetRoutesArg
) {
  if (
    typeof assetMapOrOptions === "object" &&
    assetMapOrOptions != null &&
    Array.isArray(assetMapOrOptions.bundleFileNames)
  ) {
    const { bundleFileNames, outDir, publicDir, staticAssetRoutes } =
      assetMapOrOptions;

    return getStaticAssetRoutesFileContent({
      exactEntries: buildStaticAssetRouteEntries({
        publicEntries: getPublicRouteEntries({
          baseDir: publicDir,
          fileDir: outDir,
        }),
        assetEntries: bundleFileNames.map(fileName => ({
          routePath: toRoutePath(fileName),
          filePath: toBunFilePath(path.join(outDir, fileName)),
        })),
        headers: staticAssetRoutes.headers,
      }),
    });
  }

  const assetMap = assetMapOrOptions;
  const bundleFileNames = Object.values(assetMap).map(assetUrl =>
    stripLeadingSlash(assetUrl)
  );

  return getBuildStaticAssetRoutesFile({
    bundleFileNames,
    outDir: outDirArg,
    publicDir: publicDirArg,
    staticAssetRoutes: staticAssetRoutesArg,
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
  return getPublicDirContent(baseDir).map(publicPath => ({
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
    .map(({ routePath, filePath, headers }) => {
      const headerName = getHeaderName(headers);
      const responseOptions =
        headerName == null ? "" : `, { headers: ${headerName} }`;

      return `  ${JSON.stringify(routePath)}: {\n    GET: new Response(Bun.file(${JSON.stringify(
        filePath
      )})${responseOptions}),\n    HEAD: new Response(Bun.file(${JSON.stringify(
        filePath
      )})${responseOptions}),\n  }`;
    });

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

  return transformedFieldName;
}

function validateExplicitFieldName(fieldName) {
  if (!/^[a-z][A-Za-z0-9_]*$/.test(fieldName)) {
    throw new Error(
      `Invalid explicit ResX asset field name: ${fieldName}. Use a valid ReScript record field name.`
    );
  }
}

function normalizeDevOrigin(origin) {
  return origin.replace(/\/$/, "");
}

function normalizeDevHost(host) {
  if (
    host == null ||
    host === true ||
    host === "0.0.0.0" ||
    host === "::"
  ) {
    return "localhost";
  }

  return host;
}

function normalizeFsPath(filePath) {
  return path.resolve(filePath);
}

function toPosix(filePath) {
  return filePath.replace(/\\/g, "/");
}

function stripLeadingSlash(value) {
  return value.replace(/^\/+/, "");
}

function stripUrlSearchHash(value) {
  return value?.split(/[?#]/)[0] ?? null;
}

function stripTrailingSlash(value) {
  return value.replace(/\/+$/, "");
}

function stripOutputPrefix(value) {
  return value
    .replace(new RegExp(`^${escapeForRegExp(assetVirtualModulePrefix)}`), "")
    .replace(new RegExp(`^${assetInputPrefix}`), "")
    .replace(new RegExp(`^${clientInputPrefix}`), "");
}

function escapeForRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function normalizeEmittedFileName(fileName) {
  const parsedPath = path.posix.parse(toPosix(fileName));
  const normalizedName = stripOutputPrefix(parsedPath.name);

  return path.posix.join(
    parsedPath.dir,
    `${normalizedName}${parsedPath.ext}`
  );
}

function toImportPath(fromFileName, toFileName) {
  const relativePath = path.posix.relative(
    path.posix.dirname(toPosix(fromFileName)),
    toPosix(toFileName)
  );

  if (relativePath.startsWith(".")) {
    return relativePath;
  }

  return `./${relativePath}`;
}

function getDefaultEntryGlobs(clientEntryExtensions) {
  return clientEntryExtensions.map(extension => `*${extension}`);
}

function getAssetVirtualModuleId(fieldName) {
  return `${assetVirtualModulePrefix}${fieldName}`;
}

function isAssetVirtualModuleId(id) {
  return id.startsWith(assetVirtualModulePrefix);
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
