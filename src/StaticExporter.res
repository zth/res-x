open Bun

external process: 'a = "process"
external fetch: string => promise<Response.t> = "fetch"

let debugging = true

let debug = s =>
  if debugging {
    Console.log2("[debug]", s)
  }

let log = s => Console.log2("[info]", s)

let run = async (server: Server.t, ~urls: array<string>) => {
  let serverUrl = `http://${server->Server.hostname}:${server->Server.port->Int.toString}`
  log(`Exporting ${urls->Array.length->Int.toString} URLs.`)

  let _ = await Promise.all(
    urls->Array.map(async url => {
      log(`[export] ${url} - Exporting...`)
      let res = await fetch(serverUrl ++ url)

      switch res->Response.status {
      | 200 =>
        let structure =
          url
          ->String.split("/")
          ->Array.filter(p => p !== "")
          ->Array.toReversed

        let (sliceStart, fileName) = switch structure->Array.get(0) {
        | None | Some("") => (0, "index.html")
        | Some(f) => (1, f ++ ".html")
        }

        structure->Array.push("dist")

        let dirStructure = structure->Array.slice(~start=sliceStart)->Array.toReversed

        switch dirStructure {
        | [] => ()
        | dirStructure => await Fs.mkdir(dirStructure->Array.join("/"), {recursive: true})
        }

        dirStructure->Array.push(fileName)
        let filePath = dirStructure->Array.join("/")

        let _ = await Bun.Write.writeResponseToFile(
          ~file=dirStructure->Array.join("/")->Bun.file,
          ~response=res,
        )

        log(`[export] ${url} - Wrote ${filePath}.`)

      | otherStatus => Console.error(url ++ " gave status " ++ otherStatus->Int.toString)
      }
    }),
  )

  log("Done.")

  server->Server.stop(~closeActiveConnections=true)
  process["exit"](0)
}
