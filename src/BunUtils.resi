let serveStaticFile: Request.t => promise<option<Response.t>>

let runDevServer: (~port: int) => unit

let isDev: bool

module URLSearchParams: {
  let copy: URLSearchParams.t => URLSearchParams.t
}
