type htmxHandlerConfig<'ctx> = {
  request: Bun.Request.t,
  context: 'ctx,
  headers: Bun.Headers.t,
  requestController: ResX__RequestController.t,
}

type htmxHandler<'ctx> = htmxHandlerConfig<'ctx> => promise<Jsx.element>

type renderConfig<'ctx> = {
  request: Bun.Request.t,
  headers: Bun.Headers.t,
  context: 'ctx,
  path: list<string>,
  url: Bun.URL.t,
  requestController: ResX__RequestController.t,
}

type t<'ctx> = {
  handlers: array<(Bun.method, string, htmxHandler<'ctx>)>,
  requestToContext: Bun.Request.t => promise<'ctx>,
  asyncLocalStorage: Bun.AsyncLocalStorage.t<renderConfig<'ctx>>,
}

type hxGet = string
type hxPost = string
type hxPut = string
type hxPatch = string
type hxDelete = string

let make = (~requestToContext) => {
  handlers: [],
  requestToContext,
  asyncLocalStorage: Bun.AsyncLocalStorage.make(),
}

let useContext = t => t.asyncLocalStorage->Bun.AsyncLocalStorage.getStore

let defaultRenderTitle = segments => segments->Array.joinWith(" | ")

let renderWithDocType = async (
  el,
  ~requestController: ResX__RequestController.t,
  ~renderTitle=defaultRenderTitle,
) => {
  let (content, appendToHead) = await Promise.all2((
    H.renderToString(el),
    requestController->ResX__RequestController.getAppendedHeadContent,
  ))

  // TODO: Escape? Hyperons has something

  let appendToHead = switch (
    appendToHead,
    requestController->ResX__RequestController.getTitleSegments,
  ) {
  | (appendToHead, []) => appendToHead
  | (Some(appendToHead), titleSegments) =>
    let titleElement = `<title>${renderTitle(titleSegments)}</title>`
    Some(appendToHead ++ titleElement)
  | (None, titleSegments) => Some(`<title>${renderTitle(titleSegments)}</title>`)
  }

  let content = switch appendToHead {
  | None => content
  | Some(appendToHead) => content->String.replace("</head>", appendToHead ++ "</head>")
  }

  requestController->ResX__RequestController.getDocHeader ++ content
}
let defaultHeaders = [("Content-Type", "text/html")]

type handleRequestConfig<'ctx> = {
  request: Bun.Request.t,
  server: Bun.Server.t,
  render: renderConfig<'ctx> => promise<Jsx.element>,
  setupHeaders?: unit => Bun.Headers.t,
  renderTitle?: array<string> => string,
  experimental_stream?: bool,
}

let handleRequest = async (t, {request, render, ?experimental_stream} as config) => {
  open Bun
  let stream = experimental_stream->Option.getWithDefault(false)

  let url = request->Request.url->URL.make
  let pathname = url->URL.pathname
  let targetHandler = t.handlers->Array.findMap(((handlerType, path, handler)) =>
    if handlerType === request->Request.method && path === pathname {
      Some(handler)
    } else {
      None
    }
  )

  let ctx = await t.requestToContext(request)
  let requestController = ResX__RequestController.make()

  let headers = switch config.setupHeaders {
  | Some(setupHeaders) => setupHeaders()
  | None => Bun.Headers.makeWithInit(FromArray(defaultHeaders))
  }
  let renderConfig = {
    context: ctx,
    headers,
    request,
    path: pathname
    ->String.split("/")
    ->Array.filter(s => s->String.trim !== "")
    ->List.fromArray,
    url,
    requestController,
  }

  await t.asyncLocalStorage->AsyncLocalStorage.run(renderConfig, async _token => {
    let content = switch targetHandler {
    | None => await render(renderConfig)
    | Some(handler) =>
      await handler({
        request,
        context: ctx,
        headers,
        requestController,
      })
    }

    if stream {
      let {readable, writable} = TransformStream.make({
        transform: (chunk, controller) => {
          controller->TransformStream.Controller.enqueue(chunk)
        },
      })
      let writer = writable->WritableStream.getWriter
      let textEncoder = TextEncoder.make()

      H.renderToStream(content, ~onChunk=chunk => {
        let encoded = textEncoder->TextEncoder.encode(chunk)
        writer->WritableStream.Writer.write(encoded)
      })
      ->Promise.thenResolve(_ => {
        writer->WritableStream.Writer.close
      })
      ->Promise.done

      Response.makeFromReadableStream(
        readable,
        ~options={
          status: 200,
          headers: FromArray([("Content-Type", "text/html")]),
        },
      )
    } else {
      let content = await renderWithDocType(
        content,
        ~requestController,
        ~renderTitle=?config.renderTitle,
      )
      switch (
        requestController->ResX__RequestController.getCurrentRedirect,
        requestController->ResX__RequestController.getCurrentStatus,
      ) {
      | (Some(url, status), _) => Response.makeRedirect(url, ~status?)
      | (None, status) => Response.makeWithHeaders(content, ~options={headers, status})
      }
    }
  })
}

let get = (t, path, ~handler) => {
  t.handlers->Array.push((GET, path, handler))
  path
}
let makeGet = path => {
  path
}
let implementGet = (t, path, ~handler) => {
  let _: hxGet = get(t, path, ~handler)
}

let post = (t, path, ~handler) => {
  t.handlers->Array.push((POST, path, handler))
  path
}
let makePost = path => {
  path
}
let implementPost = (t, path, ~handler) => {
  let _: hxPost = post(t, path, ~handler)
}

let put = (t, path, ~handler) => {
  t.handlers->Array.push((PUT, path, handler))
  path
}
let makePut = path => {
  path
}
let implementPut = (t, path, ~handler) => {
  let _: hxPut = put(t, path, ~handler)
}

let delete = (t, path, ~handler) => {
  t.handlers->Array.push((DELETE, path, handler))
  path
}
let makeDelete = path => {
  path
}
let implementDelete = (t, path, ~handler) => {
  let _: hxDelete = delete(t, path, ~handler)
}

let patch = (t, path, ~handler) => {
  t.handlers->Array.push((PATCH, path, handler))
  path
}
let makePatch = path => {
  path
}
let implementPatch = (t, path, ~handler) => {
  let _: hxPatch = patch(t, path, ~handler)
}

module Internal = {
  let getHandlers = t => t.handlers
}
