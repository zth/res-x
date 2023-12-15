module React = ResX__React
module ReactDOM = ResX__ReactDOM

module Handler = {
  type context = unit
  let handler = Handlers.make(~requestToContext=async _req => {
    ()
  })
}

let currentPortsUsed = Set.make()
let portsBase = 40000

let getPort = () => {
  let port = ref(None)
  while port.contents == None {
    let assignedPort = Math.Int.random(portsBase, portsBase + 10000)
    if !(currentPortsUsed->Set.has(assignedPort)) {
      currentPortsUsed->Set.add(assignedPort)
      port := Some(assignedPort)
    }
  }
  switch port.contents {
  | Some(port) => (
      port,
      () => {
        let _ = currentPortsUsed->Set.delete(port)
      },
    )
  | None => (
      -1,
      () => {
        ()
      },
    )
  }
}

module Html = {
  @react.component
  let make = (~children) => {
    <html>
      <head />
      <body> {children} </body>
    </html>
  }
}

let getResponse = async getContent => {
  let (port, unsubPort) = getPort()

  let server = Bun.serve({
    port,
    development: true,
    fetch: async (request, _server) => {
      await Handler.handler->ResX.Handlers.handleRequest({
        request,
        setupHeaders: () => {
          Headers.make(~init=FromArray([("Content-Type", "text/html")]))
        },
        render: async renderConfig => {
          getContent(renderConfig)
        },
      })
    },
  })

  let res = switch await fetch(`http://localhost:${port->Int.toString}/`) {
  | res => Ok(res)
  | exception Exn.Error(_) => Error("Failed to fetch.")
  }

  server->Bun.Server.stop(~closeActiveConnections=true)
  unsubPort()

  switch res {
  | Ok(res) => res
  | Error(err) => panic(err)
  }
}

let getContentInBody = async getContent => {
  let content = await getResponse(getContent)
  await content->Response.text
}
