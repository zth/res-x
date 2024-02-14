@val external null: Jsx.element = "null"

module FormAction = {
  type t = string
  let string = s => s
}

type htmxHandlerConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
  headers: Headers.t,
  requestController: RequestController.t,
}

type formActionConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
}

type htmxHandler<'ctx> = htmxHandlerConfig<'ctx> => promise<Jsx.element>
type formActionHandler<'ctx> = formActionConfig<'ctx> => promise<Response.t>

type renderConfig<'ctx> = {
  request: Request.t,
  headers: Headers.t,
  context: 'ctx,
  path: list<string>,
  url: URL.t,
  requestController: RequestController.t,
}

type t<'ctx> = {
  htmxHandlers: array<(method, string, htmxHandler<'ctx>)>,
  formActionHandlers: array<(string, formActionHandler<'ctx>)>,
  requestToContext: Request.t => promise<'ctx>,
  asyncLocalStorage: AsyncHooks.AsyncLocalStorage.t<renderConfig<'ctx>>,
  htmxApiPrefix: string,
  formActionHandlerApiPrefix: string,
}

type hxGet = string
type hxPost = string
type hxPut = string
type hxPatch = string
type hxDelete = string

type options = {htmxApiPrefix?: string, formActionHandlerApiPrefix?: string}

let make = (~requestToContext, ~options=?) => {
  htmxHandlers: [],
  formActionHandlers: [],
  requestToContext,
  asyncLocalStorage: AsyncHooks.AsyncLocalStorage.make(),
  htmxApiPrefix: options
  ->Option.flatMap(options => options.htmxApiPrefix)
  ->Option.getOr("/_api"),
  formActionHandlerApiPrefix: options
  ->Option.flatMap(options => options.formActionHandlerApiPrefix)
  ->Option.getOr("/_form"),
}

let useContext = t => t.asyncLocalStorage->AsyncHooks.AsyncLocalStorage.getStoreUnsafe

let defaultRenderTitle = segments => segments->Array.joinWith(" | ")

@module("./vendor/hyperons.js")
external escapeString: string => string = "escapeString"

let renderWithDocType = async (
  el,
  ~requestController: RequestController.t,
  ~renderTitle=defaultRenderTitle,
) => {
  let content = await H.renderToString(el)
  let appendToHead = await requestController->RequestController.getAppendedHeadContent

  let appendToHead = switch (appendToHead, requestController->RequestController.getTitleSegments) {
  | (appendToHead, []) => appendToHead
  | (Some(appendToHead), titleSegments) =>
    let titleElement = `<title>${renderTitle(titleSegments)->escapeString}</title>`
    Some(appendToHead ++ titleElement)
  | (None, titleSegments) => Some(`<title>${renderTitle(titleSegments)->escapeString}</title>`)
  }

  let content = switch appendToHead {
  | None => content
  | Some(appendToHead) => content->String.replace("</head>", appendToHead ++ "</head>")
  }

  requestController->RequestController.getDocHeader ++ content
}
let defaultHeaders = [("Content-Type", "text/html")]

type responseType = Default | FormActionHandler | HtmxHandler

type onBeforeSendResponse<'ctx> = {
  request: Request.t,
  response: Response.t,
  context: 'ctx,
  responseType: responseType,
}

type handleRequestConfig<'ctx> = {
  request: Request.t,
  render: renderConfig<'ctx> => promise<Jsx.element>,
  setupHeaders?: unit => Headers.t,
  renderTitle?: array<string> => string,
  experimental_stream?: bool,
  onBeforeSendResponse?: onBeforeSendResponse<'ctx> => promise<Response.t>,
}

let handleRequest = async (
  t,
  {request, render, ?experimental_stream, ?onBeforeSendResponse} as config,
) => {
  let stream = experimental_stream->Option.getOr(false)

  let url = request->Request.url->URL.make
  let pathname = url->URL.pathname

  // TODO: Can optimize when this runs
  let targetFormActionHandler = t.formActionHandlers->Array.findMap(((path, handler)) =>
    switch request->Request.method {
    | POST | GET if path === pathname => Some(handler)
    | _ => None
    }
  )

  let targetHtmxHandler = t.htmxHandlers->Array.findMap(((handlerType, path, handler)) =>
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
    let isFormAction = targetFormActionHandler->Option.isSome

    let content = switch (targetFormActionHandler, targetHtmxHandler) {
    | (Some(_), _) => null
    | (None, None) => await render(renderConfig)
    | (None, Some(handler)) =>
      await handler({
        request,
        context: ctx,
        headers,
        requestController,
      })
    }

    let responseType = switch (targetFormActionHandler, targetHtmxHandler) {
    | (Some(_), _) => FormActionHandler
    | (None, Some(_)) => HtmxHandler
    | (None, None) => Default
    }

    if isFormAction {
      let formActionHandler = targetFormActionHandler->Option.getExn
      let response = await formActionHandler({context: ctx, request})
      switch onBeforeSendResponse {
      | Some(onBeforeSendResponse) =>
        await onBeforeSendResponse({
          response,
          context: ctx,
          request,
          responseType,
        })
      | None => response
      }
    } else if stream {
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

      let response = Response.makeFromReadableStream(
        readable,
        ~options={
          status: 200,
          headers: FromArray([("Content-Type", "text/html")]),
        },
      )

      switch onBeforeSendResponse {
      | Some(onBeforeSendResponse) =>
        await onBeforeSendResponse({
          response,
          context: ctx,
          request,
          responseType,
        })
      | None => response
      }
    } else {
      let content = await renderWithDocType(
        content,
        ~requestController,
        ~renderTitle=?config.renderTitle,
      )
      let response = switch (
        requestController->RequestController.getCurrentRedirect,
        requestController->RequestController.getCurrentStatus,
      ) {
      | (Some(url, status), _) => Response.makeRedirect(url, ~status?)
      | (None, status) => Response.makeWithHeaders(content, ~options={headers, status})
      }
      switch onBeforeSendResponse {
      | Some(onBeforeSendResponse) =>
        await onBeforeSendResponse({response, context: ctx, request, responseType})
      | None => response
      }
    }
  })
}

let formAction = (t: t<_>, path, ~handler) => {
  let path = t.formActionHandlerApiPrefix ++ path
  t.formActionHandlers->Array.push((path, handler))
  path
}

let hxGet = (t: t<_>, path, ~handler) => {
  let path = t.htmxApiPrefix ++ path
  t.htmxHandlers->Array.push((GET, path, handler))
  path
}
let makeHxGetIdentifier = (t: t<_>, path) => {
  t.htmxApiPrefix ++ path
}
let implementHxGetIdentifier = (t, path, ~handler) => {
  let _: hxGet = hxGet(t, path, ~handler)
}

let hxPost = (t: t<_>, path, ~handler) => {
  let path = t.htmxApiPrefix ++ path
  t.htmxHandlers->Array.push((POST, path, handler))
  path
}
let makeHxPostIdentifier = (t: t<_>, path) => {
  t.htmxApiPrefix ++ path
}
let implementHxPostIdentifier = (t, path, ~handler) => {
  let _: hxPost = hxPost(t, path, ~handler)
}

let hxPut = (t: t<_>, path, ~handler) => {
  let path = t.htmxApiPrefix ++ path
  t.htmxHandlers->Array.push((PUT, path, handler))
  path
}
let makeHxPutIdentifier = (t: t<_>, path) => {
  t.htmxApiPrefix ++ path
}
let implementHxPutIdentifier = (t, path, ~handler) => {
  let _: hxPut = hxPut(t, path, ~handler)
}

let hxDelete = (t: t<_>, path, ~handler) => {
  let path = t.htmxApiPrefix ++ path
  t.htmxHandlers->Array.push((DELETE, path, handler))
  path
}
let makeHxDeleteIdentifier = (t: t<_>, path) => {
  t.htmxApiPrefix ++ path
}
let implementHxDeleteIdentifier = (t, path, ~handler) => {
  let _: hxDelete = hxDelete(t, path, ~handler)
}

let hxPatch = (t: t<_>, path, ~handler) => {
  let path = t.htmxApiPrefix ++ path
  t.htmxHandlers->Array.push((PATCH, path, handler))
  path
}
let makeHxPatchIdentifier = (t: t<_>, path) => {
  t.htmxApiPrefix ++ path
}
let implementHxPatchIdentifier = (t, path, ~handler) => {
  let _: hxPatch = hxPatch(t, path, ~handler)
}

module Internal = {
  let getHandlers = t => t.htmxHandlers
}
