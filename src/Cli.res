exception UsageError(string)

type buildCliOptions = {
  dev: bool,
  watch: bool,
  clean: bool,
  root: option<string>,
  help: bool,
}

type runResult =
  | ExitCode(int)
  | Watching

external process: 'process = "process"
external processExit: int => 'a = "process.exit"
external processOn: (string, unit => unit) => unit = "process.on"
external consoleLog: string => unit = "console.log"
external consoleError: string => unit = "console.error"

let printRootHelp = () =>
  consoleLog(`Usage: resx <command>

Commands:
  assets build     Build managed assets

Run \`resx assets build --help\` for command-specific options.`)

let printAssetsBuildHelp = () =>
  consoleLog(`Usage: resx assets build [options]

Options:
  --dev            Build dev assets into .resx/dev
  --watch          Watch for changes (requires --dev)
  --root <path>    Project root directory (default: current working directory)
  --clean          Clean output directory before build (default)
  --no-clean       Do not clean output directory before build
  -h, --help       Show this help`)

let parseAssetsBuildArgs = argv => {
  let options = ref({dev: false, watch: false, clean: true, root: None, help: false})
  let i = ref(0)

  while i.contents < argv->Array.length {
    let arg = argv->Array.getUnsafe(i.contents)

    switch arg {
    | "--dev" => options := {...options.contents, dev: true}
    | "--watch" => options := {...options.contents, watch: true}
    | "--clean" => options := {...options.contents, clean: true}
    | "--no-clean" => options := {...options.contents, clean: false}
    | "--root" =>
      let nextIndex = i.contents + 1
      switch argv->Array.get(nextIndex) {
      | Some(value) if !(value->String.startsWith("--")) =>
        options := {...options.contents, root: Some(value)}
        i := nextIndex
      | _ => throw(UsageError("Missing value for --root"))
      }
    | "--help" | "-h" => options := {...options.contents, help: true}
    | unknown => throw(UsageError(`Unknown option: ${unknown}`))
    }

    i := i.contents + 1
  }

  if options.contents.watch && !options.contents.dev {
    throw(UsageError("Invalid option combination: --watch requires --dev"))
  }

  options.contents
}

let runAssetsBuild = async parsed => {
  if parsed.help {
    printAssetsBuildHelp()
    ExitCode(0)
  } else {
    let root = parsed.root

    if !parsed.watch {
      await AssetPipeline.buildAssets(~root?, ~dev=parsed.dev, ~clean=parsed.clean)
      ExitCode(0)
    } else {
      let watcher = await AssetPipeline.startDevWatch(
        ~root?,
        ~clean=parsed.clean,
        ~onBuildError=error => consoleError(error->AssetPipeline.errorToString),
      )

      switch await AssetPipeline.buildAssets(~root?, ~dev=parsed.dev, ~clean=parsed.clean) {
      | () => ()
      | exception exn =>
        watcher->AssetPipeline.closeWatcher
        throw(exn)
      }

      processOn("SIGINT", () => {
        watcher->AssetPipeline.closeWatcher
        processExit(0)
      })

      processOn("SIGTERM", () => {
        watcher->AssetPipeline.closeWatcher
        processExit(0)
      })

      Watching
    }
  }
}

let run = async argv => {
  switch argv->Array.get(0) {
  | None =>
    printRootHelp()
    ExitCode(0)
  | Some("--help") | Some("-h") =>
    printRootHelp()
    ExitCode(0)
  | Some("assets") =>
    switch argv->Array.get(1) {
    | None | Some("--help") | Some("-h") =>
      printAssetsBuildHelp()
      ExitCode(0)
    | Some("build") =>
      let parsed = parseAssetsBuildArgs(argv->Array.slice(~start=2))
      await runAssetsBuild(parsed)
    | Some(other) => throw(UsageError(`Unknown assets subcommand: ${other}`))
    }
  | Some(command) => throw(UsageError(`Unknown command: ${command}`))
  }
}

let runFromArgv = async () => {
  let argv = process["argv"]->Array.slice(~start=2)

  switch await run(argv) {
  | ExitCode(code) => processExit(code)
  | Watching => ()
  | exception UsageError(message) =>
    consoleError(message)
    consoleError("Run `resx assets build --help` for usage details.")
    processExit(2)
  | exception JsExn(error) =>
    consoleError(error->AssetPipeline.errorToString)
    processExit(1)
  | exception _ =>
    consoleError("Unknown error")
    processExit(1)
  }
}
