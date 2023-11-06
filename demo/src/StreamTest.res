let port = 5555

let wait = () =>
  Promise.make((resolve, _) => {
    let _ = setTimeout(() => {
      resolve()
    }, 2000)
  })

let server = Bun.serve({
  port,
  development: BunUtils.isDev,
  fetch: async (_request, _server) => {
    open Bun

    let {readable, writable} = TransformStream.make({
      transform: (chunk, controller) => {
        controller->TransformStream.Controller.enqueue(chunk)
      },
    })

    let writer = writable->WritableStream.getWriter

    let textEncoder = TextEncoder.make()
    writer->WritableStream.Writer.write(textEncoder->TextEncoder.encode("Hello!"))

    writer->WritableStream.Writer.close

    let response = Response.makeFromReadableStream(readable)
    response->Response.headers->Headers.set("Content-Type", "text/html")

    response
  },
})
