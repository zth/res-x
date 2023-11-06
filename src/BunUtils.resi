let serveStaticFile: Bun.Request.t => promise<option<Bun.Response.t>>

let runDevServer: (~port: int) => unit

let isDev: bool
