open Test

module NodeFs = {
  type mkdirOptions = {recursive?: bool}
  type rmOptions = {recursive?: bool, force?: bool}

  @module("node:fs") @val external mkdtempSync: string => string = "mkdtempSync"
  @module("node:fs") @val external mkdirSyncWith: (string, mkdirOptions) => unit = "mkdirSync"
  @module("node:fs") @val external rmSyncWith: (string, rmOptions) => unit = "rmSync"
  @module("node:fs") @val external writeFileSync: (string, string) => unit = "writeFileSync"
}

module PluginTestHelpers = {
  type pluginModule
  type t

  type manifestEntry = {
    fieldName: string,
    rescriptFieldName: string,
  }

  type manifestOptions = {
    assetDir: string,
    assetEntryGlobs: array<string>,
    clientDirs: array<string>,
    clientEntryExtensions: array<string>,
    clientEntryGlobs: array<string>,
    extraClientEntries: Dict.t<string>,
    projectRoot: string,
  }

  external requireModule: string => pluginModule = "require"
  @get external testHelpers: pluginModule => t = "__test"
  @send external getGeneratedDevAssetMap: (t, array<manifestEntry>) => string = "getGeneratedDevAssetMap"
  @send external getManifest: (t, manifestOptions) => array<manifestEntry> = "getManifest"
  @send external getResTypeFileContent: (t, array<manifestEntry>) => string = "getResTypeFileContent"

  let modulePath = Path.join([Process.process->Process.cwd, "res-x-vite-plugin.mjs"])
  let helpers = requireModule(modulePath)->testHelpers
}

let defaultClientEntryExtensions = [".js", ".mjs", ".jsx", ".ts", ".tsx"]
let defaultEntryGlobs = defaultClientEntryExtensions->Array.map(extension => "*" ++ extension)

let withTempDir = async run => {
  let tempDir = NodeFs.mkdtempSync(Path.join([Os.tmpdir(), "resx-asset-map-"]))

  try {
    let result = await run(tempDir)
    NodeFs.rmSyncWith(tempDir, {recursive: true, force: true})
    result
  } catch {
  | exn =>
      NodeFs.rmSyncWith(tempDir, {recursive: true, force: true})
      throw(exn)
  }
}

let getManifestOptions = (~projectRoot, ~extraClientEntries=dict{}) : PluginTestHelpers.manifestOptions => {
  assetDir: "assets",
  assetEntryGlobs: defaultEntryGlobs,
  clientDirs: [],
  clientEntryExtensions: defaultClientEntryExtensions,
  clientEntryGlobs: defaultEntryGlobs,
  extraClientEntries,
  projectRoot,
}

let getManifestEntry = (
  manifest: array<PluginTestHelpers.manifestEntry>,
  fieldName,
): PluginTestHelpers.manifestEntry =>
  switch manifest->Array.find((entry: PluginTestHelpers.manifestEntry) => entry.fieldName == fieldName) {
  | Some(entry) => entry
  | None => panic(`Missing manifest entry for ${fieldName}`)
  }

let expectContains = (text, substring) =>
  expect(text->String.includes(substring))->Expect.toBe(true)

describe("asset map generation", () => {
  testAsync("uses @as for keyword asset names while preserving runtime keys", async () => {
    await withTempDir(async tempDir => {
      NodeFs.mkdirSyncWith(Path.join([tempDir, "assets"]), {recursive: true})
      NodeFs.writeFileSync(Path.join([tempDir, "assets", "type"]), "type asset")

      let manifest = PluginTestHelpers.helpers->PluginTestHelpers.getManifest(
        getManifestOptions(~projectRoot=tempDir),
      )
      let typeEntry = getManifestEntry(manifest, "type")

      expect(typeEntry.rescriptFieldName)->Expect.toBe("type_")

      let resTypeFile = PluginTestHelpers.helpers->PluginTestHelpers.getResTypeFileContent(manifest)
      resTypeFile->expectContains(`@as("type")`)
      resTypeFile->expectContains("type_: string")

      let devAssetMap =
        PluginTestHelpers.helpers->PluginTestHelpers.getGeneratedDevAssetMap(manifest)
      devAssetMap->expectContains(`"type": "/assets/type"`)
    })
  })

  testAsync("keeps existing safe field labels when keyword aliases would collide", async () => {
    await withTempDir(async tempDir => {
      NodeFs.mkdirSyncWith(Path.join([tempDir, "assets"]), {recursive: true})
      NodeFs.writeFileSync(Path.join([tempDir, "assets", "type"]), "type asset")
      NodeFs.writeFileSync(Path.join([tempDir, "assets", "type_"]), "type_ asset")

      let manifest = PluginTestHelpers.helpers->PluginTestHelpers.getManifest(
        getManifestOptions(~projectRoot=tempDir),
      )
      let typeEntry = getManifestEntry(manifest, "type")
      let typeUnderscoreEntry = getManifestEntry(manifest, "type_")

      expect(typeEntry.rescriptFieldName)->Expect.toBe("type__")
      expect(typeUnderscoreEntry.rescriptFieldName)->Expect.toBe("type_")

      let resTypeFile = PluginTestHelpers.helpers->PluginTestHelpers.getResTypeFileContent(manifest)
      resTypeFile->expectContains(`@as("type")`)
      resTypeFile->expectContains("type__: string")
      resTypeFile->expectContains("type_: string")
    })
  })

  testAsync("uses @as for keyword extra client entry names", async () => {
    await withTempDir(async tempDir => {
      NodeFs.mkdirSyncWith(Path.join([tempDir, "client"]), {recursive: true})
      NodeFs.writeFileSync(
        Path.join([tempDir, "client", "open.js"]),
        "export const openClient = true;\n",
      )

      let manifest =
        PluginTestHelpers.helpers->PluginTestHelpers.getManifest(
          getManifestOptions(~projectRoot=tempDir, ~extraClientEntries=dict{
            "open": "client/open.js",
          }),
        )
      let openEntry = getManifestEntry(manifest, "open")

      expect(openEntry.rescriptFieldName)->Expect.toBe("open_")

      let resTypeFile = PluginTestHelpers.helpers->PluginTestHelpers.getResTypeFileContent(manifest)
      resTypeFile->expectContains(`@as("open")`)
      resTypeFile->expectContains("open_: string")

      let devAssetMap =
        PluginTestHelpers.helpers->PluginTestHelpers.getGeneratedDevAssetMap(manifest)
      devAssetMap->expectContains(`"open": "/client/open.js"`)
    })
  })
})
