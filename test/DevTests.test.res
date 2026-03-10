open Test

module PluginTestHelpers = {
  type pluginModule
  type t
  type plugin

  type pluginOptions = {
    resXClientLocation: string,
    serverUri: string,
  }

  type configInput = {server: Dict.t<JSON.t>}
  type serveEnv = {command: string}
  type proxyEntry = {target: string}
  type serverConfig = {
    hmr: bool,
    proxy: Dict.t<proxyEntry>,
  }
  type configResult = {server: serverConfig}

  type manifestEntry = {
    fieldName: string,
    projectRelativePath: option<string>,
    sourcePath: string,
  }

  external requireModule: string => pluginModule = "require"
  @get external testHelpers: pluginModule => t = "__test"
  @get external defaultPluginFactory: pluginModule => pluginOptions => plugin = "default"
  @send external getGeneratedDevAssetMap: (t, array<manifestEntry>) => string = "getGeneratedDevAssetMap"
  @send external getClientEntryWrapperModule: (t, string, string, array<string>) => string =
    "getClientEntryWrapperModule"
  @send external getDevSocketProxyTarget: (t, string) => string = "getDevSocketProxyTarget"
  @send external config: (plugin, configInput, serveEnv) => configResult = "config"

  let modulePath = Path.join([Process.process->Process.cwd, "res-x-vite-plugin.mjs"])
  let module_ = requireModule(modulePath)
  let helpers = module_->testHelpers
  let makePlugin = module_->defaultPluginFactory
}

let expectContains = (text, substring) =>
  expect(text->String.includes(substring))->Expect.toBe(true)

let expectNotContains = (text, substring) =>
  expect(text->String.includes(substring))->Expect.toBe(false)

let getProxyEntry = (proxy, routePath) =>
  switch proxy->Dict.get(routePath) {
  | Some(entry) => entry
  | None => panic(`Missing proxy entry for ${routePath}`)
  }

describe("dev helper", () => {
  test("uses a same-origin dev socket and hard reloads after reconnect", () => {
    let script = Dev.getScript()

    script->expectContains(`window.location.host + "/_resx_dev"`)
    script->expectContains("Server restarting...")
    script->expectContains("window.location.reload()")
    script->expectContains("document.body.appendChild")
    script->expectNotContains("morphdom")
    script->expectNotContains(`http://localhost:9000/@vite/client`)
    script->expectNotContains("fetch(document.location.href")
    script->expectNotContains("Server connection opened.")
  })

  test("generates root-relative dev asset urls", () => {
    let assetModuleSource =
      PluginTestHelpers.helpers->PluginTestHelpers.getGeneratedDevAssetMap([
        {
          fieldName: "styles_css",
          projectRelativePath: Some("assets/styles.css"),
          sourcePath: "/Users/zth/OSS/res-x-4/assets/styles.css",
        },
        {
          fieldName: "resXClient_js",
          projectRelativePath: Some("node_modules/rescript-x/client/ResXClient.js"),
          sourcePath: "/Users/zth/OSS/res-x-4/node_modules/rescript-x/client/ResXClient.js",
        },
        {
          fieldName: "external_client_js",
          projectRelativePath: None,
          sourcePath: "/tmp/resx/external-client.js",
        },
      ])

    assetModuleSource->expectContains(`"/assets/styles.css"`)
    assetModuleSource->expectContains(`"/node_modules/rescript-x/client/ResXClient.js"`)
    assetModuleSource->expectContains(`"/@fs/tmp/resx/external-client.js"`)
    assetModuleSource->expectNotContains("http://localhost")
  })

  test("loads client-entry css links before importing the wrapper module", () => {
    let wrapper =
      PluginTestHelpers.helpers->PluginTestHelpers.getClientEntryWrapperModule(
        "assets/client_loader.js",
        "assets/client.js",
        ["assets/admin.css"],
      )

    wrapper->expectContains(`link[rel="stylesheet"]`)
    wrapper->expectContains(`import("./client.js")`)
  })

  test("disables Vite HMR while proxying the same-origin dev socket", () => {
    let plugin = PluginTestHelpers.makePlugin({
      resXClientLocation: "client/ResXClient.js",
      serverUri: "http://127.0.0.1:4444",
    })
    let config =
      plugin->PluginTestHelpers.config(
        {
          server: dict{},
        },
        {command: "serve"},
      )

    expect(config.server.hmr)->Expect.toBe(false)
    expect(
      (config.server.proxy->getProxyEntry("/_resx_dev")).target,
    )->Expect.toBe("http://127.0.0.1:4445/")
  })

  test("derives the proxied dev socket target from the app server uri", () => {
    expect(
      PluginTestHelpers.helpers->PluginTestHelpers.getDevSocketProxyTarget("http://127.0.0.1:5555"),
    )->Expect.toBe("http://127.0.0.1:5556/")
    expect(
      PluginTestHelpers.helpers->PluginTestHelpers.getDevSocketProxyTarget("https://example.test"),
    )->Expect.toBe("https://example.test:444/")
  })
})
