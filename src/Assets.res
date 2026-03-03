external process: 'process = "process"
external consoleWarn: string => unit = "console.warn"
external consoleError: string => unit = "console.error"

let isDevelopment = process["env"]["NODE_ENV"] !== "production"

let startDevPromise: ref<option<promise<unit>>> = ref(None)
let startDevWatcher: ref<option<AssetPipeline.watcher>> = ref(None)
let startedRoot: ref<option<string>> = ref(None)

let closeWatcher = () =>
  switch startDevWatcher.contents {
  | Some(watcher) =>
    watcher->AssetPipeline.closeWatcher
    startDevWatcher := None
  | None => ()
  }

let startDev = async (~root=?, ()) => {
  if !isDevelopment {
    ()
  } else {
    let resolvedRoot = await AssetPipeline.resolveProjectRoot(~root?)

    switch startDevPromise.contents {
    | Some(existingPromise) =>
      switch startedRoot.contents {
      | Some(existingRoot) if existingRoot !== resolvedRoot =>
        consoleWarn(
          `[resx] startDev() already initialized for ${existingRoot}; ignoring additional root ${resolvedRoot}`,
        )
      | _ => ()
      }

      await existingPromise
    | None =>
      let startupPromise = (async () => {
        let watcher = await AssetPipeline.startDevWatch(
          ~root=resolvedRoot,
          ~clean=true,
          ~onBuildError=error =>
            consoleError(`[resx] dev asset rebuild failed\n${error->AssetPipeline.errorToString}`),
        )
        startDevWatcher := Some(watcher)

        switch await AssetPipeline.buildAssets(~root=resolvedRoot, ~dev=true, ~clean=true) {
        | () => ()
        | exception exn =>
          closeWatcher()
          throw(exn)
        }

        startedRoot := Some(resolvedRoot)
      })()

      startDevPromise := Some(startupPromise)

      switch await startupPromise {
      | () => ()
      | exception exn =>
        startDevPromise := None
        startedRoot := None
        closeWatcher()
        throw(exn)
      }
    }
  }
}
