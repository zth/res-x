external process: 'process = "process"

let isDev = process["env"]["NODE_ENV"] !== "production"

let projectRootPromise: ref<option<promise<string>>> = ref(None)

let getProjectRoot = () =>
  switch projectRootPromise.contents {
  | Some(existingPromise) => existingPromise
  | None =>
    let nextPromise = AssetPipeline.resolveProjectRoot()
    projectRootPromise := Some(nextPromise)
    nextPromise
  }

let serveStaticFile = async request => {
  let projectRoot = await getProjectRoot()
  await AssetPipeline.serveStaticFileFromBuild(~request, ~projectRoot, ~isDev)
}

let runDevServer = (~port: int) => {
  let _unusedPort = port
  ()
}

module URLSearchParams = {
  let copy = search =>
    URLSearchParams.makeWithInit(
      search
      ->URLSearchParams.entries
      ->Dict.fromIterator
      ->Object,
    )
}
