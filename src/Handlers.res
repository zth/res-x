external null: Jsx.element = "null"
external string: string => Jsx.element = "%identity"

module FormAction = {
  type t = string
  let string = s => s
  let toEndpointURL = s => s
}

type htmxHandlerConfig<'ctx, 'securityPolicyData> = {
  request: Request.t,
  context: 'ctx,
  headers: Headers.t,
  requestController: RequestController.t,
  securityPolicyData: 'securityPolicyData,
}

type formActionConfig<'ctx, 'securityPolicyData> = {
  request: Request.t,
  context: 'ctx,
  securityPolicyData: 'securityPolicyData,
}

type htmxHandler<'ctx, 'securityPolicyData> = htmxHandlerConfig<
  'ctx,
  'securityPolicyData,
> => promise<Jsx.element>
type formActionHandler<'ctx, 'securityPolicyData> = formActionConfig<
  'ctx,
  'securityPolicyData,
> => promise<Response.t>

type htmxRunConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
  headers: Headers.t,
  requestController: RequestController.t,
}

type formActionRunConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
}

type htmxRegistration<'ctx> = {
  method: method,
  path: string,
  csrfCheckOpt: option<bool>,
  run: htmxRunConfig<'ctx> => promise<Jsx.element>,
}

type formActionRegistration<'ctx> = {
  path: string,
  csrfCheckOpt: option<bool>,
  run: formActionRunConfig<'ctx> => promise<Response.t>,
}

type renderConfig<'ctx> = {
  request: Request.t,
  headers: Headers.t,
  context: 'ctx,
  path: list<string>,
  url: URL.t,
  requestController: RequestController.t,
}

type defaultCsrfCheck =
  | ForAllMethods(bool)
  | PerMethod({
      get: option<bool>,
      post: option<bool>,
      put: option<bool>,
      patch: option<bool>,
      delete: option<bool>,
    })

type t<'ctx> = {
  htmxHandlers: array<htmxRegistration<'ctx>>,
  formActionHandlers: array<formActionRegistration<'ctx>>,
  requestToContext: Request.t => promise<'ctx>,
  asyncLocalStorage: AsyncHooks.AsyncLocalStorage.t<renderConfig<'ctx>>,
  htmxApiPrefix: string,
  formActionHandlerApiPrefix: string,
  defaultCsrfCheck: defaultCsrfCheck,
}

type hxGet = string
type hxPost = string
type hxPut = string
type hxPatch = string
type hxDelete = string

type options = {
  htmxApiPrefix?: string,
  formActionHandlerApiPrefix?: string,
  defaultCsrfCheck?: defaultCsrfCheck,
}

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
  defaultCsrfCheck: options
  ->Option.flatMap(options => options.defaultCsrfCheck)
  ->Option.getOr(ForAllMethods(false)),
}

let isCsrfEnabledFor = (t: t<_>, m: method) =>
  switch t.defaultCsrfCheck {
  | ForAllMethods(v) => v
  | PerMethod({get, post, put, patch, delete}) =>
    switch m {
    | GET => get->Option.getOr(false)
    | POST => post->Option.getOr(false)
    | PUT => put->Option.getOr(false)
    | PATCH => patch->Option.getOr(false)
    | DELETE => delete->Option.getOr(false)
    | _ => false
    }
  }

let useContext = t => t.asyncLocalStorage->AsyncHooks.AsyncLocalStorage.getStoreUnsafe

let defaultRenderTitle = segments => segments->Array.join(" | ")

@module("./vendor/hyperons.js")
external escapeString: string => string = "escapeString"

let renderWithDocType = async (
  el,
  ~requestController: RequestController.t,
  ~renderTitle=defaultRenderTitle,
  ~onAfterRender: unit => promise<unit>=async () => (),
) => {
  let content = await H.renderToString(el)

  await onAfterRender()
  let appendToHead = await requestController->RequestController.getAppendedHeadContent
  let appendBeforeBodyEnd = await requestController->RequestController.getAppendedBeforeBodyEndContent

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

  let content = switch appendBeforeBodyEnd {
  | None => content
  | Some(appendBeforeBodyEnd) =>
    content->String.replace("</body>", appendBeforeBodyEnd ++ "</body>")
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

type onBeforeBuildResponse<'ctx> = {
  request: Request.t,
  context: 'ctx,
  responseType: responseType,
  requestController: RequestController.t,
}

type onAfterBuildResponse<'ctx> = {
  request: Request.t,
  context: 'ctx,
  responseType: responseType,
  requestController: RequestController.t,
}

type handleRequestConfig<'ctx> = {
  request: Request.t,
  render: renderConfig<'ctx> => promise<Jsx.element>,
  setupHeaders?: unit => Headers.t,
  renderTitle?: array<string> => string,
  experimental_stream?: bool,
  onBeforeSendResponse?: onBeforeSendResponse<'ctx> => promise<Response.t>,
  onBeforeBuildResponse?: onBeforeBuildResponse<'ctx> => promise<unit>,
  onAfterBuildResponse?: onAfterBuildResponse<'ctx> => promise<unit>,
}

let handleRequest = async (
  t,
  {
    request,
    render,
    ?experimental_stream,
    ?onBeforeSendResponse,
    ?onBeforeBuildResponse,
    ?onAfterBuildResponse,
  } as config,
) => {
  let stream = experimental_stream->Option.getOr(false)

  let url = request->Request.url->URL.make
  let pathname = url->URL.pathname

  // TODO: Can optimize when this runs
  let targetFormActionHandler = t.formActionHandlers->Array.findMap(reg =>
    switch request->Request.method {
    | POST | GET if reg.path === pathname => Some(reg)
    | _ => None
    }
  )

  let targetHtmxHandler = t.htmxHandlers->Array.findMap(reg =>
    if reg.method === request->Request.method && reg.path === pathname {
      Some(reg)
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
    | (None, Some(reg)) =>
      let csrfEnabled = reg.csrfCheckOpt->Option.getOr(t->isCsrfEnabledFor(reg.method))
      let csrfOk = switch csrfEnabled {
      | true => await CSRF.verifyRequest(request)
      | false => true
      }
      if !csrfOk {
        requestController->RequestController.setStatus(403)
        string("Invalid CSRF token.")
      } else {
        await reg.run({
          request,
          context: ctx,
          headers,
          requestController,
        })
      }
    }

    let responseType = switch (targetFormActionHandler, targetHtmxHandler) {
    | (Some(_), _) => FormActionHandler
    | (None, Some(_)) => HtmxHandler
    | (None, None) => Default
    }

    // Runs before the actual response is built, HTML is rendered, etc.
    switch onBeforeBuildResponse {
    | None => ()
    | Some(onBeforeBuildResponse) =>
      await onBeforeBuildResponse({
        context: ctx,
        request,
        responseType,
        requestController,
      })
    }

    if isFormAction {
      let reg = targetFormActionHandler->Option.getOrThrow
      let csrfEnabled = reg.csrfCheckOpt->Option.getOr(t->isCsrfEnabledFor(request->Request.method))
      let csrfOk = switch csrfEnabled {
      | true => await CSRF.verifyRequest(request)
      | false => true
      }
      let response = if !csrfOk {
        Response.make("Invalid CSRF token.", ~options={status: 403})
      } else {
        await reg.run({context: ctx, request})
      }
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
        writer->WritableStream.WritableStreamDefaultWriter.write(encoded)->Promise.ignore
      })
      ->Promise.thenResolve(_ => {
        writer->WritableStream.WritableStreamDefaultWriter.close
      })
      ->Promise.ignore

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
      let onAfterRender: option<unit => promise<unit>> = switch onAfterBuildResponse {
      | Some(onAfterBuildResponse) =>
        Some(
          async () =>
            await onAfterBuildResponse({
              context: ctx,
              request,
              responseType,
              requestController,
            }),
        )
      | None => None
      }

      let content = await renderWithDocType(
        content,
        ~requestController,
        ~renderTitle=?config.renderTitle,
        ~onAfterRender?,
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

let makeHtmxRunner: (
  SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  htmxHandler<'ctx, 'securityPolicyData>,
) => htmxRunConfig<'ctx> => promise<Jsx.element> = (securityPolicy, handler) =>
  async ({request, context, headers, requestController}) =>
    switch await securityPolicy({request, context}) {
    | SecurityPolicy.Allow(meta) =>
      await handler({
        request,
        context,
        headers,
        requestController,
        securityPolicyData: meta,
      })
    | SecurityPolicy.Block({message, code}) =>
      requestController->RequestController.setStatus(code->Option.getOr(403))
      string(message->Option.getOr("Not Allowed."))
    }

let makeFormActionRunner: (
  SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  formActionHandler<'ctx, 'securityPolicyData>,
) => formActionRunConfig<'ctx> => promise<Response.t> = (securityPolicy, handler) =>
  async ({request, context}) =>
    switch await securityPolicy({request, context}) {
    | SecurityPolicy.Allow(meta) =>
      await handler({
        request,
        context,
        securityPolicyData: meta,
      })
    | SecurityPolicy.Block({message, code}) =>
      Response.make(
        message->Option.getOr("Not Allowed."),
        ~options={status: code->Option.getOr(403)},
      )
    }

let formAction = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let path = t.formActionHandlerApiPrefix ++ path
  let run = makeFormActionRunner(securityPolicy, handler)
  t.formActionHandlers->Array.push({
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
  path
}

let getHtmxPath = (t: t<_>, path) => {
  t.htmxApiPrefix ++ path
}

let hxGet = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let path = t.htmxApiPrefix ++ path
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: GET,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
  path
}
let hxGetRef = (t: t<_>, path) => {
  t->getHtmxPath(path)
}
let hxGetDefine = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: GET,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
}
let hxGetToEndpointURL = s => s

let hxPost = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let path = t->getHtmxPath(path)
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: POST,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
  path
}
let hxPostRef = (t: t<_>, path) => {
  t->getHtmxPath(path)
}
let hxPostDefine = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: POST,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
}
let hxPostToEndpointURL = s => s

let hxPut = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let path = t->getHtmxPath(path)
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: PUT,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
  path
}
let hxPutRef = (t: t<_>, path) => {
  t->getHtmxPath(path)
}
let hxPutDefine = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: PUT,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
}
let hxPutToEndpointURL = s => s

let hxDelete = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let path = t->getHtmxPath(path)
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: DELETE,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
  path
}
let hxDeleteRef = (t: t<_>, path) => {
  t->getHtmxPath(path)
}
let hxDeleteDefine = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: DELETE,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
}
let hxDeleteToEndpointURL = s => s

let hxPatch = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let path = t->getHtmxPath(path)
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: PATCH,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
  path
}
let hxPatchRef = (t: t<_>, path) => {
  t->getHtmxPath(path)
}
let hxPatchDefine = (t: t<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let run = makeHtmxRunner(securityPolicy, handler)
  t.htmxHandlers->Array.push({
    method: PATCH,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
}
let hxPatchToEndpointURL = s => s

module Internal = {
  type htmxRegistration<'ctx> = htmxRegistration<'ctx>
  let getHandlers = t => t.htmxHandlers
}
