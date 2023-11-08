let serveStaticFile: Bun.Request.t => promise<option<Bun.Response.t>>

let runDevServer: (~port: int) => unit

let isDev: bool

module URLSearchParams: {
  let copy: Bun.URLSearchParams.t => Bun.URLSearchParams.t
}
