external process: 'process = "process"

let isDev = process["env"]["NODE_ENV"] !== "production"

type globConfig = {
  dot?: bool,
  cwd?: string,
}

@module("fast-glob")
external glob: (array<string>, globConfig) => promise<array<string>> = "glob"

let loadStaticFiles = async (~root=?) => {
  await glob(
    switch isDev {
    | true => ["public/**/*", "assets/**/*"]
    | false => ["dist/**/*"]
    },
    {
      dot: true,
      cwd: switch root {
      | None => process["cwd"]()
      | Some(cwd) => cwd
      },
    },
  )
}

let staticFiles = ref(None)

let serveStaticFile = async request => {
  open Bun

  let staticFiles = switch staticFiles.contents {
  | None =>
    let files = await loadStaticFiles()
    let files =
      files
      ->Array.map(f => {
        (
          switch isDev {
          | true if f->String.startsWith("public/") => f->String.sliceToEnd(~start=7)
          | false if f->String.startsWith("dist/") => f->String.sliceToEnd(~start=5)
          | _ => f
          },
          f,
        )
      })
      ->Map.fromArray
    staticFiles := Some(files)
    files
  | Some(s) => s
  }

  let url = request->Request.url->URL.make
  let pathname = url->URL.pathname

  let path = pathname->String.split("/")->Array.filter(p => p !== "")
  let joined = path->Array.join("/")

  switch staticFiles->Map.get(joined) {
  | None => None
  | Some(fileLoc) =>
    let bunFile = Bun.file("./" ++ fileLoc)

    Some(
      switch bunFile->BunFile.size {
      | 0. => Response.make("", ~options={status: 404})
      | _ => Response.makeFromFile(bunFile)
      },
    )
  }
}

let runDevServer = (~port) => {
  let _devServer = Bun.serveWithWebSocket({
    port: port + 1,
    development: true,
    websocket: {
      open_: _v => {
        ()
      },
    },
    fetch: async (request, server) => {
      open Bun

      if server->Server.upgrade(request) {
        Response.defer
      } else {
        Response.make("", ~options={status: 404})
      }
    },
  })
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
