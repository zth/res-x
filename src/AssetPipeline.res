type watcher = {close: unit => unit}

type rmOptions = {recursive: bool, force: bool}
type readFileOptions = {encoding: string}
type fsWatchOptions = {recursive: bool, encoding: string}

@module("node:fs/promises") external fsStat: string => promise<Fs.Stats.t> = "stat"
@module("node:fs/promises") external fsRealpath: string => promise<string> = "realpath"
@module("node:fs/promises") external fsReadFile: string => promise<Buffer.t> = "readFile"
@module("node:fs/promises")
external fsReadFileUtf8: (string, readFileOptions) => promise<string> = "readFile"
@module("node:fs/promises")
external fsWriteFileBuffer: (string, Buffer.t) => promise<unit> = "writeFile"
@module("node:fs/promises") external fsRm: (string, rmOptions) => promise<unit> = "rm"

type fsWatcher
@send external fsWatcherClose: fsWatcher => unit = "close"
@module("node:fs")
external fsWatch: (string, fsWatchOptions, (string, option<string>) => unit) => fsWatcher = "watch"

@module("node:module") external createRequire: string => string => 'a = "createRequire"

@val external jsonStringify: 'a => string = "JSON.stringify"

@val external __dirname: string = "__dirname"

@set external setErrorName: (JsError.t, string) => unit = "name"
@set external setErrorCode: (JsError.t, string) => unit = "code"

external errorToString: 'a => string = "String"

type postcssProcessOptions = {
  from: string,
  @as("to") to_: string,
  map: bool,
}

type postcssProcessor
type postcssResult = {css: string}
type postcssEnv = {env: string}
@send
external postcssProcess: (
  postcssProcessor,
  string,
  postcssProcessOptions,
) => promise<postcssResult> = "process"

@get external getConfigPlugins: 'a => Nullable.t<'b> = "plugins"

let jsEntryExtensions = [".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs"]
let cssEntryExtension = ".css"

let devOutputDir = Path.join2(".resx", "dev")
let prodOutputDir = "dist"

let generatedDir = Path.join2("src", "__generated__")
let generatedResFile = Path.join2(generatedDir, "ResXAssets.res")
let generatedJsFile = Path.join2(generatedDir, "res-x-assets.js")

let manifestFile = "resx-assets.json"
let resXClientKey = "resXClient_js"
let resXClientOutput = "resx-client.js"

type managedFile = {
  relPath: string,
  absPath: string,
  realPath: string,
}

type managedAssetRecord = {
  sourceRelPath: string,
  outputRelPath: string,
  outputPath: string,
  urlPath: string,
  contentHash: string,
}

type emittedAsset = {
  outputRelPath: string,
  outputPath: string,
  urlPath: string,
  contentHash: string,
}

type copiedPublicRecord = {
  relPath: string,
  outputPath: string,
  contentHash: string,
}

type keyedRecord = {
  key: string,
  urlPath: string,
  contentHash: string,
}

type classifiedAssets = {
  jsEntries: array<managedFile>,
  cssEntries: array<managedFile>,
  copiedAssets: array<managedFile>,
}

type serveRoots = {
  managedAssetsRoot: string,
  staticRoot: string,
}

type bunBuildRunResult = {
  ok: bool,
  logs: array<Bun.Build.logMessage>,
  bytes: option<Buffer.t>,
}

let makeResXUsageError = message => {
  let error = JsError.make(message)
  error->setErrorName("ResXUsageError")
  error->setErrorCode("RESX_USAGE")
  error->JsError.toJsExn
}

let makeResXBuildError = message => {
  let error = JsError.make(message)
  error->setErrorName("ResXBuildError")
  error->setErrorCode("RESX_BUILD")
  error->JsError.toJsExn
}

let throwJsError = (error: JsExn.t) => throw(JsExn(error))

let isNullish = value => {
  let nullableValue: Nullable.t<'a> = Obj.magic(value)
  switch nullableValue->Nullable.toOption {
  | None => true
  | Some(_) => false
  }
}

let boolFromAny = value => {
  let boolValue: bool = Obj.magic(value)
  boolValue
}

let tryOrNone = f =>
  switch f() {
  | value => Some(value)
  | exception _ => None
  }

let tryOrNoneAsync = async f =>
  switch await f() {
  | value => Some(value)
  | exception _ => None
  }

let isJsFunction = value => Type.typeof(value) == #function
let isJsBoolean = value => Type.typeof(value) == #boolean
let isJsString = value => Type.typeof(value) == #string
let isJsObject = value => Type.typeof(value) == #object

let toPosixPath = value => {
  if Path.sep == "/" {
    value
  } else {
    value->String.split(Path.sep)->Array.join("/")
  }
}

let isPathInside = (~candidatePath, ~basePath) => {
  let relative = Path.relative(~from=basePath, ~to_=candidatePath)
  relative == "" || (!(relative->String.startsWith("..")) && !Path.isAbsolute(relative))
}

let pathExists = async targetPath => {
  switch await Fs.access(targetPath) {
  | () => true
  | exception _ => false
  }
}

let pathExistsSync = targetPath => Fs.existsSync(targetPath)

let sha256HexBuffer = input => {
  let hash = RescriptBun.Crypto.createHash("sha256")
  hash->RescriptBun.Crypto.Hash.update(input)
  hash->RescriptBun.Crypto.Hash.digest->Buffer.toStringWithEncoding(StringEncoding.hex)
}

let sha256HexString = input => sha256HexBuffer(Buffer.fromString(input))

let hash8Buffer = input => sha256HexBuffer(input)->String.slice(~start=0, ~end=8)

let ensureTrailingSlash = value =>
  if value->String.endsWith("/") {
    value
  } else {
    `${value}/`
  }

let writeIfChangedBuffer = async (~filePath, ~content) => {
  let previous = switch await fsReadFile(filePath) {
  | bytes => Some(bytes)
  | exception _ => None
  }

  switch previous {
  | Some(existing) if Buffer.compare(existing, content) == 0 => false
  | _ =>
    await Fs.mkdir(Path.dirname(filePath), {recursive: true})
    await fsWriteFileBuffer(filePath, content)
    true
  }
}

let writeIfChangedString = async (~filePath, ~content) => {
  let bytes = Buffer.fromString(content)
  ignore(await writeIfChangedBuffer(~filePath, ~content=bytes))
}

let isAsciiLower = code => code >= 97 && code <= 122
let isAsciiUpper = code => code >= 65 && code <= 90
let isAsciiDigit = code => code >= 48 && code <= 57

let sanitizeFieldChars = input => {
  let chars = input->Array.fromString
  let sanitized = chars->Array.map(char => {
    if char == "_" {
      "_"
    } else {
      let code = char->String.charCodeAtUnsafe(0)
      if isAsciiLower(code) || isAsciiUpper(code) || isAsciiDigit(code) {
        char
      } else {
        "_"
      }
    }
  })
  sanitized->Array.join("")
}

let toRescriptFieldName = (fieldName, existing: Set.t<string>) => {
  let slashNormalized = fieldName->String.split("/")->Array.join("__")
  let transformedRef = ref(sanitizeFieldChars(slashNormalized))

  if transformedRef.contents == "" {
    transformedRef := "a"
  } else {
    let first = transformedRef.contents->String.slice(~start=0, ~end=1)
    let code = first->String.charCodeAtUnsafe(0)
    if !isAsciiLower(code) {
      transformedRef := `a${transformedRef.contents}`
    }
  }

  while Set.has(existing, transformedRef.contents) {
    transformedRef := `${transformedRef.contents}_`
  }

  transformedRef.contents
}

let jsEntryExtensionSet = Set.fromArray(jsEntryExtensions)

let formatBunLogs = (logs, projectRoot) => {
  if logs->Array.length == 0 {
    ""
  } else {
    let messages = logs->Array.map(log => {
      let (rawMessage, position) = switch log {
      | Bun.Build.BuildMessage(payload) => (payload.message, payload.position->Null.toOption)
      | Bun.Build.ResolveMessage(payload) => (payload.message, payload.position->Null.toOption)
      }

      let message = if rawMessage != "" {
        rawMessage
      } else {
        "Unknown build error"
      }

      switch position {
      | Some(location) =>
        let filePath = location.file
        let relative = if isPathInside(~candidatePath=filePath, ~basePath=projectRoot) {
          Path.relative(~from=projectRoot, ~to_=filePath)->toPosixPath
        } else {
          filePath
        }

        let line = Int.toString(location.line)
        let column = Int.toString(location.column)

        `${relative}:${line}:${column} ${message}`
      | None => message
      }
    })

    messages->Array.join("\n")
  }
}

let normalizeRootInput = root =>
  switch root {
  | Some(value) if value != "" => value
  | _ => Process.process->Process.cwd
  }

let scanGlobPaths = (~pattern, ~cwd, ~dot) => {
  let glob = Bun.Glob.make(pattern)
  let iter = glob->Bun.Glob.scanSync(~options={cwd, dot, onlyFiles: true, followSymlinks: false})
  Array.fromIterator(iter)->Array.map(toPosixPath)
}

let scanGlobPatternsUniqueSorted = (~patterns, ~cwd, ~dot) => {
  let seen = Set.make()
  let results: array<string> = []

  for i in 0 to patterns->Array.length - 1 {
    let pattern = patterns->Array.getUnsafe(i)
    let scanned = scanGlobPaths(~pattern, ~cwd, ~dot)

    for j in 0 to scanned->Array.length - 1 {
      let relPath = scanned->Array.getUnsafe(j)
      if !Set.has(seen, relPath) {
        Set.add(seen, relPath)
        results->Array.push(relPath)
      }
    }
  }

  results->Array.sort(String.compare)
  results
}

let resolveProjectRoot = async (~root=?) => {
  let rootInput = normalizeRootInput(root)
  let absolute = Path.resolve([rootInput])

  if !(await pathExists(absolute)) {
    throwJsError(makeResXBuildError(`Project root not found: ${absolute}`))
  }

  let stats = await fsStat(absolute)
  if !(stats->Fs.Stats.isDirectory) {
    throwJsError(makeResXBuildError(`Project root is not a directory: ${absolute}`))
  }

  await fsRealpath(absolute)
}

let resolveClientSource = () => Path.resolve([__dirname, "ResXClient.js"])

let discoverManagedFiles = async (~projectRoot, ~directoryName): array<managedFile> => {
  let baseDir = Path.join2(projectRoot, directoryName)
  if !(await pathExists(baseDir)) {
    []
  } else {
    let projectRootReal = await fsRealpath(projectRoot)
    let sortedRelPaths = scanGlobPatternsUniqueSorted(~patterns=["**/*"], ~cwd=baseDir, ~dot=false)

    let files: array<managedFile> = []

    for i in 0 to sortedRelPaths->Array.length - 1 {
      let relPath = sortedRelPaths->Array.getUnsafe(i)
      let absPath = Path.join2(baseDir, relPath)

      switch await fsRealpath(absPath) {
      | realPath =>
        if isPathInside(~candidatePath=realPath, ~basePath=projectRootReal) {
          files->Array.push({
            relPath,
            absPath,
            realPath,
          })
          ()
        }
      | exception _ => ()
      }
    }

    files
  }
}

let hasJsEntryExtension = extension => {
  Set.has(jsEntryExtensionSet, extension->String.toLowerCase)
}

let classifyAssetFiles = (assetFiles: array<managedFile>): classifiedAssets => {
  let jsEntries: array<managedFile> = []
  let cssEntries: array<managedFile> = []
  let copiedAssets: array<managedFile> = []

  for i in 0 to assetFiles->Array.length - 1 {
    let file = assetFiles->Array.getUnsafe(i)
    let extension = file.relPath->Path.extname->String.toLowerCase

    if hasJsEntryExtension(extension) {
      jsEntries->Array.push(file)
      ()
    } else if extension == cssEntryExtension {
      cssEntries->Array.push(file)
      ()
    } else {
      copiedAssets->Array.push(file)
      ()
    }
  }

  {jsEntries, cssEntries, copiedAssets}
}

let jsOutputRelativePath = sourceRelPath => {
  let parsed = Path.Posix.parse(sourceRelPath)
  let name = `${parsed.name}.js`
  if parsed.dir != "" {
    `${parsed.dir}/${name}`
  } else {
    name
  }
}

let hashedRelativePath = (~relPath, ~bytes) => {
  let parsed = Path.Posix.parse(relPath)
  let name = `${parsed.name}-${hash8Buffer(bytes)}${parsed.ext}`
  if parsed.dir != "" {
    `${parsed.dir}/${name}`
  } else {
    name
  }
}

let extractLogs = (result: Bun.Build.buildOutput) => result.logs

let runBunBuild = async (~entryPath, ~minify) => {
  let result = await tryOrNoneAsync(() => Bun.build({
    entrypoints: [entryPath],
    target: Bun.Browser,
    format: Bun.Build.Esm,
    splitting: false,
    minify: Bun.Build.Bool(minify),
    sourcemap: Bun.Build.None,
  }))

  switch result {
  | None => {
      ok: false,
      logs: [],
      bytes: None,
    }
  | Some(result) =>
    if !result.success {
      {
        ok: false,
        logs: extractLogs(result),
        bytes: None,
      }
    } else {
      let outputs = result.outputs

      if outputs->Array.length == 0 {
        {
          ok: false,
          logs: [],
          bytes: None,
        }
      } else {
        let primary = switch outputs->Array.find(output => output.kind == Bun.Build.BuildArtifact.EntryPoint) {
        | Some(value) => value
        | None => outputs->Array.getUnsafe(0)
        }

        let rawBytes = await primary->Bun.Build.BuildArtifact.asBlob->Blob.arrayBuffer
        let bytes = Buffer.fromArrayBuffer(rawBytes)
        {
          ok: true,
          logs: extractLogs(result),
          bytes: Some(bytes),
        }
      }
    }
  }
}

let createRootRequire = projectRoot => {
  let packageJson = Path.join2(projectRoot, "package.json")
  if pathExistsSync(packageJson) {
    createRequire(packageJson)
  } else {
    createRequire(Path.join2(projectRoot, "index.js"))
  }
}

let maybeTransformCssWithPostcss = async (~entryPath, ~projectRoot) => {
  let configCandidates = [
    Path.join2(projectRoot, "postcss.config.js"),
    Path.join2(projectRoot, "postcss.config.cjs"),
  ]

  let configPathRef: ref<option<string>> = ref(None)

  for i in 0 to configCandidates->Array.length - 1 {
    if configPathRef.contents == None {
      let candidate = configCandidates->Array.getUnsafe(i)
      if await pathExists(candidate) {
        configPathRef := Some(candidate)
      }
    }
  }

  switch configPathRef.contents {
  | None => None
  | Some(configPath) =>
    let rootRequire = tryOrNone(() => createRootRequire(projectRoot))

    switch rootRequire {
    | None => None
    | Some(rootRequire) =>
      let postcssFactory: option<array<'a> => postcssProcessor> =
        switch tryOrNone(() => rootRequire("postcss")) {
        | Some(value) => Some(Obj.magic(value))
        | None => None
        }

      switch postcssFactory {
      | None => None
      | Some(postcssFactory) =>
        let configValue: option<'a> = tryOrNone(() => rootRequire(configPath))

        switch configValue {
        | None => None
        | Some(initialConfig) =>
          let config = if isJsFunction(initialConfig) {
            tryOrNone(() => {
              let runConfig: postcssEnv => 'a = Obj.magic(initialConfig)
              runConfig({env: "development"})
            })
          } else {
            Some(initialConfig)
          }

          switch config {
          | None => None
          | Some(config) =>
            let plugins: array<'a> = []
            let configuredPlugins = config->getConfigPlugins->Nullable.toOption

            switch configuredPlugins {
            | None => ()
            | Some(configuredPluginsAny) =>
              if Array.isArray(configuredPluginsAny) {
                let configuredPluginArray: array<'a> = Obj.magic(configuredPluginsAny)

                for i in 0 to configuredPluginArray->Array.length - 1 {
                  let pluginEntry = configuredPluginArray->Array.getUnsafe(i)

                  if isNullish(pluginEntry) {
                    ()
                  } else if isJsBoolean(pluginEntry) && !boolFromAny(pluginEntry) {
                    ()
                  } else if isJsFunction(pluginEntry) {
                    plugins->Array.push(pluginEntry)
                    ()
                  } else if isJsString(pluginEntry) {
                    let name: string = Obj.magic(pluginEntry)
                    switch rootRequire(name) {
                    | loaded =>
                      if isJsFunction(loaded) {
                        let createPlugin: unit => 'a = Obj.magic(loaded)
                        plugins->Array.push(createPlugin())
                        ()
                      } else {
                        plugins->Array.push(loaded)
                        ()
                      }
                    | exception _ => ()
                    }
                  } else if Array.isArray(pluginEntry) {
                    let pair: array<'a> = Obj.magic(pluginEntry)
                    switch pair->Array.get(0) {
                    | Some(nameAny) if isJsString(nameAny) =>
                      let name: string = Obj.magic(nameAny)
                      switch rootRequire(name) {
                      | loaded =>
                        if isJsFunction(loaded) {
                          let createPlugin: 'a => 'b = Obj.magic(loaded)
                          switch pair->Array.get(1) {
                          | Some(options) =>
                            plugins->Array.push(createPlugin(options))
                            ()
                          | None =>
                            let createPluginNoArg: unit => 'b = Obj.magic(loaded)
                            plugins->Array.push(createPluginNoArg())
                            ()
                          }
                        } else {
                          plugins->Array.push(loaded)
                          ()
                        }
                      | exception _ => ()
                      }
                    | _ => plugins->Array.push(pluginEntry)
                    }
                  } else {
                    plugins->Array.push(pluginEntry)
                    ()
                  }
                }
              } else if isJsObject(configuredPluginsAny) {
                let configuredPluginEntries: array<(string, 'a)> = (Obj.magic(configuredPluginsAny): dict<'a>)->Dict.toArray

                for i in 0 to configuredPluginEntries->Array.length - 1 {
                  let (name, pluginOptions) = configuredPluginEntries->Array.getUnsafe(i)

                  if isJsBoolean(pluginOptions) && !boolFromAny(pluginOptions) {
                    ()
                  } else {
                    switch rootRequire(name) {
                    | loaded =>
                      if isJsFunction(loaded) {
                        if (
                          isNullish(pluginOptions) ||
                          (isJsBoolean(pluginOptions) && boolFromAny(pluginOptions))
                        ) {
                          let createPlugin: unit => 'a = Obj.magic(loaded)
                          plugins->Array.push(createPlugin())
                          ()
                        } else {
                          let createPlugin: 'a => 'b = Obj.magic(loaded)
                          plugins->Array.push(createPlugin(pluginOptions))
                          ()
                        }
                      } else {
                        plugins->Array.push(loaded)
                        ()
                      }
                    | exception _ => ()
                    }
                  }
                }
              } else {
                ()
              }
            }

            if plugins->Array.length == 0 {
              None
            } else {
              let source = await fsReadFileUtf8(entryPath, {encoding: "utf8"})

              switch {
                let processor = postcssFactory(plugins)
                await postcssProcess(
                  processor,
                  source,
                  {
                    from: entryPath,
                    to_: entryPath,
                    map: false,
                  },
                )
              } {
              | transformed => Some(Buffer.fromString(transformed.css))
              | exception _ => None
              }
            }
          }
        }
      }
    }
  }
}

let buildJavaScript = async (~entryPath, ~projectRoot, ~mode) => {
  let built = await runBunBuild(~entryPath, ~minify=mode == "prod")
  if built.ok {
    switch built.bytes {
    | Some(bytes) => bytes
    | None => throwJsError(makeResXBuildError(`JavaScript build failed: ${entryPath}`))
    }
  } else {
    let details = formatBunLogs(built.logs, projectRoot)
    throwJsError(
      makeResXBuildError(details != "" ? details : `JavaScript build failed: ${entryPath}`),
    )
  }
}

let buildCss = async (~entryPath, ~projectRoot, ~mode) => {
  let built = await runBunBuild(~entryPath, ~minify=mode == "prod")

  switch await maybeTransformCssWithPostcss(~entryPath, ~projectRoot) {
  | Some(transformed) => transformed
  | None =>
    if built.ok {
      switch built.bytes {
      | Some(bytes) => bytes
      | None => throwJsError(makeResXBuildError(`CSS build failed: ${entryPath}`))
      }
    } else {
      let details = formatBunLogs(built.logs, projectRoot)
      throwJsError(makeResXBuildError(details != "" ? details : `CSS build failed: ${entryPath}`))
    }
  }
}

let emitManagedAsset = async (~mode, ~outputAssetsDir, ~logicalRelPath, ~bytes): emittedAsset => {
  let outputRelPath = if mode == "prod" {
    hashedRelativePath(~relPath=logicalRelPath, ~bytes)
  } else {
    logicalRelPath
  }

  let normalizedRelPath = toPosixPath(outputRelPath)
  let destination = Path.join2(outputAssetsDir, normalizedRelPath)

  await Fs.mkdir(Path.dirname(destination), {recursive: true})
  await fsWriteFileBuffer(destination, bytes)

  {
    outputRelPath: normalizedRelPath,
    outputPath: destination,
    urlPath: `/${Path.Posix.join(["assets", normalizedRelPath])->toPosixPath}`,
    contentHash: sha256HexBuffer(bytes),
  }
}

let copyPublicFiles = async (~publicFiles: array<managedFile>, ~projectRoot, ~outputRoot) => {
  let _ = projectRoot
  let copied: array<copiedPublicRecord> = []

  for i in 0 to publicFiles->Array.length - 1 {
    let file = publicFiles->Array.getUnsafe(i)
    let destination = Path.join2(outputRoot, file.relPath)

    if isPathInside(~candidatePath=destination, ~basePath=outputRoot) {
      await Fs.mkdir(Path.dirname(destination), {recursive: true})
      await Fs.copyFile(file.absPath, ~dest=destination)
      let bytes = await fsReadFile(destination)

      copied->Array.push({
        relPath: file.relPath,
        outputPath: destination,
        contentHash: sha256HexBuffer(bytes),
      })
      ()
    }
  }

  copied
}

let buildGeneratedJs = keyedRecords => {
  let lines =
    keyedRecords->Array.map(record => `  ${record.key}: ${jsonStringify(record.urlPath)},`)
  `export const assets = {\n${lines->Array.join("\n")}\n};\n`
}

let buildGeneratedRes = (~keyedRecords, ~sourceByKey: dict<string>) => {
  let lines: array<string> = []
  lines->Array.push("// Generated by ResX, do not edit manually")
  lines->Array.push("")
  lines->Array.push("type assets = {")
  lines->Array.push("  /** ResX Client Bundle */")
  lines->Array.push("  resXClient_js: string,")

  for i in 0 to keyedRecords->Array.length - 1 {
    let record = keyedRecords->Array.getUnsafe(i)
    if record.key != resXClientKey {
      let source = switch Dict.get(sourceByKey, record.key) {
      | Some(value) => value
      | None => record.key
      }

      let escapedSource = source->String.split("`")->Array.join("\\`")
      lines->Array.push("")
      lines->Array.push(`  /** \`${escapedSource}\` */`)
      lines->Array.push(`  ${record.key}: string,`)
      ()
    }
  }

  lines->Array.push("}")
  lines->Array.push("")
  lines->Array.push("@module(\"./res-x-assets.js\") external assets: assets = \"assets\"")
  lines->Array.push("")

  lines->Array.join("\n")
}

let buildManifest = (~mode, ~keyedRecords) => {
  let seedParts =
    keyedRecords->Array.map(record => `${record.key}|${record.urlPath}|${record.contentHash}`)
  let fingerprint = sha256HexString(seedParts->Array.join("\n"))

  let assetsLines: array<string> = []
  for i in 0 to keyedRecords->Array.length - 1 {
    let record = keyedRecords->Array.getUnsafe(i)
    let comma = if i < keyedRecords->Array.length - 1 {
      ","
    } else {
      ""
    }
    assetsLines->Array.push(
      `    ${jsonStringify(record.key)}: ${jsonStringify(record.urlPath)}${comma}`,
    )
  }

  let assetsBody = if assetsLines->Array.length == 0 {
    "{}"
  } else {
    `{
${assetsLines->Array.join("\n")}
  }`
  }

  `{
  "version": 1,
  "mode": ${jsonStringify(mode)},
  "assets": ${assetsBody},
  "fingerprint": ${jsonStringify(fingerprint)}
}
`
}

let cleanOutputDirectory = async (~outputRoot, ~projectRoot) => {
  if !isPathInside(~candidatePath=outputRoot, ~basePath=projectRoot) {
    throwJsError(makeResXBuildError(`Refusing to clean outside project root: ${outputRoot}`))
  }

  await fsRm(outputRoot, {recursive: true, force: true})
}

let buildAssets = async (~root=?, ~dev=false, ~clean=true) => {
  let mode = if dev {
    "dev"
  } else {
    "prod"
  }
  let projectRoot = await resolveProjectRoot(~root?)

  let outputRoot = if mode == "dev" {
    Path.join2(projectRoot, devOutputDir)
  } else {
    Path.join2(projectRoot, prodOutputDir)
  }

  let outputAssetsDir = Path.join2(outputRoot, "assets")

  if clean {
    await cleanOutputDirectory(~outputRoot, ~projectRoot)
  }

  await Fs.mkdir(outputAssetsDir, {recursive: true})

  let assetFiles = await discoverManagedFiles(~projectRoot, ~directoryName="assets")
  let publicFiles = await discoverManagedFiles(~projectRoot, ~directoryName="public")
  let classified = classifyAssetFiles(assetFiles)

  let managedAssetRecords: array<managedAssetRecord> = []

  for i in 0 to classified.jsEntries->Array.length - 1 {
    let entry = classified.jsEntries->Array.getUnsafe(i)
    let bytes = await buildJavaScript(~entryPath=entry.absPath, ~projectRoot, ~mode)
    let emitted = await emitManagedAsset(
      ~mode,
      ~outputAssetsDir,
      ~logicalRelPath=jsOutputRelativePath(entry.relPath),
      ~bytes,
    )

    managedAssetRecords->Array.push({
      sourceRelPath: entry.relPath,
      outputRelPath: emitted.outputRelPath,
      outputPath: emitted.outputPath,
      urlPath: emitted.urlPath,
      contentHash: emitted.contentHash,
    })
    ()
  }

  for i in 0 to classified.cssEntries->Array.length - 1 {
    let entry = classified.cssEntries->Array.getUnsafe(i)
    let bytes = await buildCss(~entryPath=entry.absPath, ~projectRoot, ~mode)
    let emitted = await emitManagedAsset(
      ~mode,
      ~outputAssetsDir,
      ~logicalRelPath=entry.relPath,
      ~bytes,
    )

    managedAssetRecords->Array.push({
      sourceRelPath: entry.relPath,
      outputRelPath: emitted.outputRelPath,
      outputPath: emitted.outputPath,
      urlPath: emitted.urlPath,
      contentHash: emitted.contentHash,
    })
    ()
  }

  for i in 0 to classified.copiedAssets->Array.length - 1 {
    let file = classified.copiedAssets->Array.getUnsafe(i)
    let bytes = await fsReadFile(file.absPath)
    let emitted = await emitManagedAsset(
      ~mode,
      ~outputAssetsDir,
      ~logicalRelPath=file.relPath,
      ~bytes,
    )

    managedAssetRecords->Array.push({
      sourceRelPath: file.relPath,
      outputRelPath: emitted.outputRelPath,
      outputPath: emitted.outputPath,
      urlPath: emitted.urlPath,
      contentHash: emitted.contentHash,
    })
    ()
  }

  managedAssetRecords->Array.sort((a, b) => String.compare(a.sourceRelPath, b.sourceRelPath))

  let clientSource = resolveClientSource()
  let clientBytes = await buildJavaScript(~entryPath=clientSource, ~projectRoot, ~mode)
  let emittedClient = await emitManagedAsset(
    ~mode,
    ~outputAssetsDir,
    ~logicalRelPath=resXClientOutput,
    ~bytes=clientBytes,
  )

  if mode == "prod" {
    let _copied = await copyPublicFiles(~publicFiles, ~projectRoot, ~outputRoot)
  }

  let usedKeys = Set.make()
  Set.add(usedKeys, resXClientKey)

  let sourceByKey: dict<string> = Dict.make()
  Dict.set(sourceByKey, resXClientKey, "resXClient.js")

  let keyedRecords: array<keyedRecord> = [
    {
      key: resXClientKey,
      urlPath: emittedClient.urlPath,
      contentHash: emittedClient.contentHash,
    },
  ]

  for i in 0 to managedAssetRecords->Array.length - 1 {
    let record = managedAssetRecords->Array.getUnsafe(i)
    let key = toRescriptFieldName(record.sourceRelPath, usedKeys)
    Set.add(usedKeys, key)
    Dict.set(sourceByKey, key, record.sourceRelPath)

    keyedRecords->Array.push({
      key,
      urlPath: record.urlPath,
      contentHash: record.contentHash,
    })
    ()
  }

  keyedRecords->Array.sort((a, b) => String.compare(a.key, b.key))

  let generatedResPath = Path.join2(projectRoot, generatedResFile)
  let generatedJsPath = Path.join2(projectRoot, generatedJsFile)

  await writeIfChangedString(
    ~filePath=generatedResPath,
    ~content=buildGeneratedRes(~keyedRecords, ~sourceByKey),
  )
  await writeIfChangedString(~filePath=generatedJsPath, ~content=buildGeneratedJs(keyedRecords))

  let manifestPath = Path.join2(outputRoot, manifestFile)
  let manifestText = buildManifest(~mode, ~keyedRecords)
  await writeIfChangedString(~filePath=manifestPath, ~content=manifestText)

  ()
}

let shouldTriggerSrcRebuild = filename => {
  switch filename {
  | None => false
  | Some(value) if value == "" => false
  | Some(value) => {
      let normalized = toPosixPath(value)
      normalized == "ResXClient.js" || normalized == "ResXClient.res"
    }
  }
}

let makeDebouncedTask = (~task: unit => promise<unit>, ~waitMs) => {
  let timer: ref<option<Timers.Timeout.t>> = ref(None)
  let running = ref(false)
  let pending = ref(false)

  let rec schedule = () => {
    switch timer.contents {
    | Some(existing) => Timers.clearTimeout(existing)
    | None => ()
    }

    timer := Some(Timers.setTimeout(() => {
          timer := None
          let _ = runOnce()
        }, waitMs))
  }

  and runOnce = async () => {
    if running.contents {
      pending := true
    } else {
      running := true

      switch await task() {
      | () => ()
      | exception _ => ()
      }

      running := false
      if pending.contents {
        pending := false
        schedule()
      }
    }
  }

  schedule
}

let watchDirectory = (~targetPath, ~onChange) => {
  if !pathExistsSync(targetPath) {
    None
  } else {
    switch fsWatch(targetPath, {recursive: true, encoding: "utf8"}, (_eventType, filename) => {
      onChange(filename)
    }) {
    | watcher => Some(watcher)
    | exception _ => None
    }
  }
}

let startDevWatch = async (~root=?, ~clean=true, ~onBuildError=?) => {
  let projectRoot = await resolveProjectRoot(~root?)

  let notifyError = switch onBuildError {
  | Some(callback) => callback
  | None => _ => ()
  }

  let rebuild = makeDebouncedTask(~task=async () => {
    switch await buildAssets(~root=projectRoot, ~dev=true, ~clean) {
    | () => ()
    | exception JsExn(error) => notifyError(error)
    | exception _ => notifyError(JsError.make("Unknown build error")->JsError.toJsExn)
    }
  }, ~waitMs=120)

  let watchers: array<fsWatcher> = []

  switch watchDirectory(~targetPath=Path.join2(projectRoot, "assets"), ~onChange=_ => rebuild()) {
  | Some(value) =>
    watchers->Array.push(value)
    ()
  | None => ()
  }

  switch watchDirectory(~targetPath=Path.join2(projectRoot, "public"), ~onChange=_ => rebuild()) {
  | Some(value) =>
    watchers->Array.push(value)
    ()
  | None => ()
  }

  switch watchDirectory(~targetPath=Path.join2(projectRoot, "src"), ~onChange=filename => {
    if shouldTriggerSrcRebuild(filename) {
      rebuild()
    }
  }) {
  | Some(value) =>
    watchers->Array.push(value)
    ()
  | None => ()
  }

  let watchPatterns = ["assets/**/*", "public/**/*", "src/ResXClient.*"]
  let pollBusy = ref(false)

  let computeWatchSignature = async () => {
    let normalized = scanGlobPatternsUniqueSorted(
      ~patterns=watchPatterns,
      ~cwd=projectRoot,
      ~dot=true,
    )

    let parts: array<string> = []

    for i in 0 to normalized->Array.length - 1 {
      let relPath = normalized->Array.getUnsafe(i)
      let absPath = Path.join2(projectRoot, relPath)

      switch await fsStat(absPath) {
      | stats =>
        parts->Array.push(`${relPath}:${Int.toString(stats.size)}:${Float.toString(stats.mtimeMs)}`)
        ()
      | exception _ => ()
      }
    }

    sha256HexString(parts->Array.join("\n"))
  }

  let previousSignature = ref(await computeWatchSignature())

  let poller = Timers.setInterval(() => {
    if pollBusy.contents {
      ()
    } else {
      pollBusy := true

      let _ = (
        async () => {
          switch await computeWatchSignature() {
          | nextSignature =>
            if nextSignature != previousSignature.contents {
              previousSignature := nextSignature
              rebuild()
            }
          | exception _ => ()
          }

          pollBusy := false
        }
      )()
    }
  }, 500)

  {
    close: () => {
      Timers.clearInterval(poller)

      for i in 0 to watchers->Array.length - 1 {
        switch watchers->Array.getUnsafe(i)->fsWatcherClose {
        | () => ()
        | exception _ => ()
        }
      }
    },
  }
}

let closeWatcher = watcher => watcher.close()

let decodePathname = pathname => {
  let current = ref(pathname)
  let failed = ref(false)

  for _index in 0 to 3 {
    if !failed.contents {
      switch decodeURIComponent(current.contents) {
      | decoded =>
        if decoded == current.contents {
          ()
        } else {
          current := decoded
        }
      | exception _ => failed := true
      }
    }
  }

  if failed.contents {
    None
  } else {
    Some(current.contents)
  }
}

let stripLeadingSlashes = value => {
  let current = ref(value)
  while current.contents->String.startsWith("/") {
    current := current.contents->String.slice(~start=1)
  }
  current.contents
}

let sanitizeUrlPath = pathname => {
  switch decodePathname(pathname) {
  | None => None
  | Some(decoded) =>
    let normalizedSlashes = decoded->String.split("\\")->Array.join("/")
    let startsWithSlash = normalizedSlashes->String.startsWith("/")
    let withSlash = if startsWithSlash {
      normalizedSlashes
    } else {
      `/${normalizedSlashes}`
    }
    let segments = withSlash->String.split("/")

    let blocked = ref(false)
    for i in 0 to segments->Array.length - 1 {
      if segments->Array.getUnsafe(i) == ".." {
        blocked := true
      }
    }

    if blocked.contents {
      None
    } else {
      let normalized = Path.Posix.normalize(withSlash)
      if normalized->String.startsWith("/") {
        Some(normalized)
      } else {
        None
      }
    }
  }
}

let getServeRoots = (~projectRoot, ~isDev): serveRoots =>
  if isDev {
    {
      managedAssetsRoot: Path.join2(projectRoot, "assets"),
      staticRoot: Path.join2(projectRoot, "public"),
    }
  } else {
    {
      managedAssetsRoot: Path.join2(Path.join2(projectRoot, prodOutputDir), "assets"),
      staticRoot: Path.join2(projectRoot, prodOutputDir),
    }
  }

let resolveServedFilePath = async (~baseRoot, ~relativePath) => {
  let relativePosix = stripLeadingSlashes(toPosixPath(relativePath))
  let target = Path.resolve([baseRoot, relativePosix])

  if !isPathInside(~candidatePath=target, ~basePath=baseRoot) {
    None
  } else {
    switch await fsStat(target) {
    | stats =>
      if !(stats->Fs.Stats.isFile) {
        None
      } else {
        switch await fsRealpath(target) {
        | realTarget =>
          switch await fsRealpath(baseRoot) {
          | realBase =>
            if isPathInside(~candidatePath=realTarget, ~basePath=realBase) {
              Some(target)
            } else {
              None
            }
          | exception _ => None
          }
        | exception _ => None
        }
      }
    | exception _ => None
    }
  }
}

let jsSourceCandidatesFromRequest = relativePath => {
  let parsed = Path.Posix.parse(relativePath)
  let base = if parsed.dir != "" {
    `${parsed.dir}/${parsed.name}`
  } else {
    parsed.name
  }
  jsEntryExtensions->Array.map(ext => `${base}${ext}`)
}

let responseWithContentType = (~body, ~contentType) => {
  let headers = Headers.make()
  headers->Headers.set("Content-Type", contentType)
  Response.makeWithHeaders(body, ~options={headers: headers})
}

let responseWithStatus = (~status) => Response.make("", ~options={status: status})

let fileResponseFromPath = filePath => Response.makeFromFile(Bun.file(filePath))

let bufferToUtf8String = buffer => buffer->Buffer.toStringWithEncoding(StringEncoding.utf8)

let requestUrlPathname = request => request->Request.url->URL.make->URL.pathname

let resolveDevManagedAssetResponse = async (~projectRoot, ~managedAssetsRoot, ~relativePath) => {
  let extension = relativePath->Path.Posix.extname->String.toLowerCase

  if extension == ".js" {
    let sourcePathRef = ref(await resolveServedFilePath(~baseRoot=managedAssetsRoot, ~relativePath))

    if sourcePathRef.contents == None {
      let sourceCandidates = jsSourceCandidatesFromRequest(relativePath)

      for i in 0 to sourceCandidates->Array.length - 1 {
        if sourcePathRef.contents == None {
          sourcePathRef :=
            (
              await resolveServedFilePath(
                ~baseRoot=managedAssetsRoot,
                ~relativePath=sourceCandidates->Array.getUnsafe(i),
              )
            )
        }
      }
    }

    switch sourcePathRef.contents {
    | None => None
    | Some(sourcePath) =>
      let jsBytes = await buildJavaScript(~entryPath=sourcePath, ~projectRoot, ~mode="dev")
      Some(
        responseWithContentType(
          ~body=bufferToUtf8String(jsBytes),
          ~contentType="text/javascript; charset=utf-8",
        ),
      )
    }
  } else if extension == ".css" {
    switch await resolveServedFilePath(~baseRoot=managedAssetsRoot, ~relativePath) {
    | None => None
    | Some(sourcePath) =>
      let cssBytes = await buildCss(~entryPath=sourcePath, ~projectRoot, ~mode="dev")
      Some(
        responseWithContentType(
          ~body=bufferToUtf8String(cssBytes),
          ~contentType="text/css; charset=utf-8",
        ),
      )
    }
  } else {
    switch await resolveServedFilePath(~baseRoot=managedAssetsRoot, ~relativePath) {
    | None => None
    | Some(exactPath) => Some(fileResponseFromPath(exactPath))
    }
  }
}

let suspiciousRootNames = [
  "bin",
  "etc",
  "home",
  "opt",
  "private",
  "proc",
  "root",
  "sbin",
  "sys",
  "tmp",
  "usr",
  "var",
  "windows",
]

let hasSuspiciousRoot = value => {
  suspiciousRootNames->Array.includes(value)
}

let serveStaticFileFromBuild = async (~request, ~projectRoot, ~isDev) => {
  let pathname = requestUrlPathname(request)

  switch sanitizeUrlPath(pathname) {
  | None => Some(responseWithStatus(~status=403))
  | Some(sanitized) =>
    let segments = sanitized->String.split("/")
    let firstSegment = switch segments->Array.find(segment => segment != "") {
    | Some(value) => value
    | None => ""
    }

    if hasSuspiciousRoot(firstSegment) {
      Some(responseWithStatus(~status=403))
    } else if firstSegment == "src" {
      let sourceRelative = sanitized->String.slice(~start=1)
      let sourceCandidate = Path.resolve([projectRoot, sourceRelative])
      if (
        isPathInside(~candidatePath=sourceCandidate, ~basePath=projectRoot) &&
        pathExistsSync(sourceCandidate)
      ) {
        Some(responseWithStatus(~status=403))
      } else {
        None
      }
    } else if sanitized == "/" {
      None
    } else {
      let roots = getServeRoots(~projectRoot, ~isDev)
      let managedAssetsRequest = sanitized == "/assets" || sanitized->String.startsWith("/assets/")

      if managedAssetsRequest {
        let relative = if sanitized == "/assets" {
          ""
        } else {
          sanitized->String.slice(~start=8)
        }

        if isDev {
          switch await resolveDevManagedAssetResponse(
            ~projectRoot,
            ~managedAssetsRoot=roots.managedAssetsRoot,
            ~relativePath=relative,
          ) {
          | Some(response) => Some(response)
          | None => Some(responseWithStatus(~status=404))
          | exception exn =>
            Console.error(
              `[resx] failed to serve dev asset /assets/${relative}\n${exn->errorToString}`,
            )
            Some(responseWithStatus(~status=500))
          }
        } else {
          switch await resolveServedFilePath(
            ~baseRoot=roots.managedAssetsRoot,
            ~relativePath=relative,
          ) {
          | Some(filePath) => Some(fileResponseFromPath(filePath))
          | None => Some(responseWithStatus(~status=404))
          }
        }
      } else {
        let relative = sanitized->String.slice(~start=1)
        switch await resolveServedFilePath(~baseRoot=roots.staticRoot, ~relativePath=relative) {
        | Some(filePath) => Some(fileResponseFromPath(filePath))
        | None => None
        }
      }
    }
  }
}
