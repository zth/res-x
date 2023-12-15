type htmxHandlerConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
  headers: Headers.t,
  requestController: RequestController.t,
}

type htmxHandler<'ctx> = htmxHandlerConfig<'ctx> => promise<Jsx.element>

type renderConfig<'ctx> = {
  request: Request.t,
  headers: Headers.t,
  context: 'ctx,
  path: list<string>,
  url: URL.t,
  requestController: RequestController.t,
}

type t<'ctx> = {
  handlers: array<(method, string, htmxHandler<'ctx>)>,
  requestToContext: Request.t => promise<'ctx>,
  asyncLocalStorage: AsyncHooks.AsyncLocalStorage.t<renderConfig<'ctx>>,
}

type hxGet = string
type hxPost = string
type hxPut = string
type hxPatch = string
type hxDelete = string

let make = (~requestToContext) => {
  handlers: [],
  requestToContext,
  asyncLocalStorage: AsyncHooks.AsyncLocalStorage.make(),
}

let useContext = t => t.asyncLocalStorage->AsyncHooks.AsyncLocalStorage.getStoreUnsafe

let defaultRenderTitle = segments => segments->Array.joinWith(" | ")

let renderWithDocType = async (
  el,
  ~requestController: RequestController.t,
  ~renderTitle=defaultRenderTitle,
) => {
  let (content, appendToHead) = await Promise.all2((
    H.renderToString(el),
    requestController->RequestController.getAppendedHeadContent,
  ))

  // TODO: Escape? Hyperons has something

  let appendToHead = switch (appendToHead, requestController->RequestController.getTitleSegments) {
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

  requestController->RequestController.getDocHeader ++ content
}
let defaultHeaders = [("Content-Type", "text/html")]

type handleRequestConfig<'ctx> = {
  request: Request.t,
  render: renderConfig<'ctx> => promise<Jsx.element>,
  setupHeaders?: unit => Headers.t,
  renderTitle?: array<string> => string,
  experimental_stream?: bool,
}

let handleRequest = async (t, {request, render, ?experimental_stream} as config) => {
  let stream = experimental_stream->Option.getOr(false)

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
  let requestController = RequestController.make()

  let headers = switch config.setupHeaders {
  | Some(setupHeaders) => setupHeaders()
  | None => Headers.make(~init=FromArray(defaultHeaders))
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

  await t.asyncLocalStorage->AsyncHooks.AsyncLocalStorage.run(renderConfig, async _token => {
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
        writer->WritableStream.WritableStreamDefaultWriter.write(encoded)->Promise.done
      })
      ->Promise.thenResolve(_ => {
        writer->WritableStream.WritableStreamDefaultWriter.close
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
        requestController->RequestController.getCurrentRedirect,
        requestController->RequestController.getCurrentStatus,
      ) {
      | (Some(url, status), _) => Response.makeRedirect(url, ~status?)
      | (None, status) => Response.makeWithHeaders(content, ~options={headers, status})
      }
    }
  })
}

let hxGet = (t, path, ~handler) => {
  t.handlers->Array.push((GET, path, handler))
  path
}
let makeHxGetIdentifier = path => {
  path
}
let implementHxGetIdentifier = (t, path, ~handler) => {
  let _: hxGet = hxGet(t, path, ~handler)
}

let hxPost = (t, path, ~handler) => {
  t.handlers->Array.push((POST, path, handler))
  path
}
let makeHxPostIdentifier = path => {
  path
}
let implementHxPostIdentifier = (t, path, ~handler) => {
  let _: hxPost = hxPost(t, path, ~handler)
}

let hxPut = (t, path, ~handler) => {
  t.handlers->Array.push((PUT, path, handler))
  path
}
let makeHxPutIdentifier = path => {
  path
}
let implementHxPutIdentifier = (t, path, ~handler) => {
  let _: hxPut = hxPut(t, path, ~handler)
}

let hxDelete = (t, path, ~handler) => {
  t.handlers->Array.push((DELETE, path, handler))
  path
}
let makeHxDeleteIdentifier = path => {
  path
}
let implementHxDeleteIdentifier = (t, path, ~handler) => {
  let _: hxDelete = hxDelete(t, path, ~handler)
}

let hxPatch = (t, path, ~handler) => {
  t.handlers->Array.push((PATCH, path, handler))
  path
}
let makeHxPatchIdentifier = path => {
  path
}
let implementHxPatchIdentifier = (t, path, ~handler) => {
  let _: hxPatch = hxPatch(t, path, ~handler)
}

module Internal = {
  let getHandlers = t => t.handlers
}
