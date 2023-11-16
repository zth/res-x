let port = 4444

let server = Bun.serve({
  port,
  development: ResX.BunUtils.isDev,
  fetch: async (request, server) => {
    switch await ResX.BunUtils.serveStaticFile(request) {
    | Some(staticResponse) => staticResponse
    | None =>
      await HtmxHandler.handler->ResX.Handlers.handleRequest({
        request,
        server,
        setupHeaders: () => {
          Headers.make(~init=FromArray([("Content-Type", "text/html")]))
        },
        render: async ({path, requestController, headers}) => {
          switch path {
          | list{"sitemap.xml"} => <SiteMap />
          | appRoutes =>
            requestController->ResX.RequestController.appendTitleSegment("Test App")
            <Html>
              <div>
                <Navigation />
                {switch appRoutes {
                | list{"start" | ""} | list{} =>
                  headers->Headers.set("Cache-Control", "public, immutable, max-age=900")
                  <div> {H.string("Start page!")} </div>
                | list{"moved"} =>
                  requestController->ResX.RequestController.redirect("/start", ~status=302)
                | list{"user", ...userRoutes} =>
                  userRoutes->UserRoutes.match(~headers, ~requestController)
                | _ => <FourOhFour setGenericTitle=true />
                }}
              </div>
            </Html>
          }
        },
      })
    }
  },
})

let portString = server->Bun.Server.port->Int.toString

Console.log(`Listening! on localhost:${portString}`)

if ResX.BunUtils.isDev {
  ResX.BunUtils.runDevServer(~port)
}
