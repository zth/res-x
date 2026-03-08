external process: 'process = "process"

let isDev = process["env"]["NODE_ENV"] !== "production"

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
