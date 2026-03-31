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
type endpointConfig<'ctx, 'securityPolicyData> = {
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
type endpointHandler<'ctx, 'securityPolicyData> = endpointConfig<
  'ctx,
  'securityPolicyData,
> => promise<Response.t>

type responseRunConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
}
type htmxRunConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
  headers: Headers.t,
  requestController: RequestController.t,
}
type formActionRunConfig<'ctx> = responseRunConfig<'ctx>
type endpointRunConfig<'ctx> = responseRunConfig<'ctx>

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

type endpointRegistration<'ctx> = {
  method: method,
  path: string,
  csrfCheckOpt: option<bool>,
  run: endpointRunConfig<'ctx> => promise<Response.t>,
}

type apiRegistration<'ctx> =
  | HtmxRegistration(htmxRegistration<'ctx>)
  | EndpointRegistration(endpointRegistration<'ctx>)

type apiHandlerKind =
  | HtmxApiHandler
  | EndpointApiHandler

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

type state<'ctx> = {
  mutable apiHandlersByRoute: Belt.Map.String.t<apiRegistration<'ctx>>,
  mutable formActionHandlersByPath: Belt.Map.String.t<formActionRegistration<'ctx>>,
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
type endpointGet = string
type endpointPost = string
type endpointPut = string
type endpointPatch = string
type endpointDelete = string

type options = {
  htmxApiPrefix?: string,
  formActionHandlerApiPrefix?: string,
  defaultCsrfCheck?: defaultCsrfCheck,
}

let getHtmxRouteKey = (method: method, path: string) => `${(method :> string)}:${path}`

let warnDuplicateFormActionHandler = path => {
  Console.warn(`[ResX.Handlers] Duplicate form action registration ignored for ${path}.`)
}

let apiHandlerKindLabel = kind =>
  switch kind {
  | HtmxApiHandler => "HTMX handler"
  | EndpointApiHandler => "endpoint"
  }

let getApiHandlerKind = registration =>
  switch registration {
  | HtmxRegistration(_) => HtmxApiHandler
  | EndpointRegistration(_) => EndpointApiHandler
  }

let getApiRegistrationPathAndMethod = registration =>
  switch registration {
  | HtmxRegistration(registration) => (registration.path, registration.method)
  | EndpointRegistration(registration) => (registration.path, registration.method)
  }

let warnDuplicateApiHandler = (~incomingKind, ~existingKind, method: method, path) => {
  switch (incomingKind, existingKind) {
  | (HtmxApiHandler, HtmxApiHandler) =>
    Console.warn(
      `[ResX.Handlers] Duplicate HTMX handler registration ignored for ${(method :> string)} ${path}.`,
    )
  | (EndpointApiHandler, EndpointApiHandler) =>
    Console.warn(
      `[ResX.Handlers] Duplicate endpoint registration ignored for ${(method :> string)} ${path}.`,
    )
  | _ =>
    Console.warn(
      `[ResX.Handlers] ${incomingKind->apiHandlerKindLabel} registration ignored for ${(method :> string)} ${path} because that API route is already registered by an existing ${existingKind->apiHandlerKindLabel}.`,
    )
  }
}

let warnFormActionShadowsApiHandler = (~kind, method: method, path) => {
  Console.warn(
    `[ResX.Handlers] Form action registration for ${path} shadows an existing ${kind->apiHandlerKindLabel} for ${(method :> string)} ${path}.`,
  )
}

let warnApiHandlerShadowedByFormAction = (~kind, method: method, path) => {
  Console.warn(
    `[ResX.Handlers] ${kind->apiHandlerKindLabel} registration for ${(method :> string)} ${path} is shadowed by an existing form action route on the same path.`,
  )
}

let warnIfFormActionShadowsApiHandler = (state: state<_>, path) => {
  let warnIfShadowed = method =>
    switch state.apiHandlersByRoute->Belt.Map.String.get(getHtmxRouteKey(method, path)) {
    | Some(registration) =>
      warnFormActionShadowsApiHandler(
        ~kind=registration->getApiHandlerKind,
        method,
        path,
      )
    | None => ()
    }

  warnIfShadowed(GET)
  warnIfShadowed(POST)
}

let warnIfApiHandlerIsShadowedByFormAction = (
  state: state<_>,
  ~kind,
  method: method,
  path,
) =>
  switch method {
  | GET | POST if state.formActionHandlersByPath->Belt.Map.String.has(path) =>
    warnApiHandlerShadowedByFormAction(~kind, method, path)
  | _ => ()
  }

let registerFormActionHandler = (
  state: state<'ctx>,
  registration: formActionRegistration<'ctx>,
) => {
  if !(state.formActionHandlersByPath->Belt.Map.String.has(registration.path)) {
    state->warnIfFormActionShadowsApiHandler(registration.path)
    state.formActionHandlersByPath = state.formActionHandlersByPath->Belt.Map.String.set(
      registration.path,
      registration,
    )
  } else {
    warnDuplicateFormActionHandler(registration.path)
  }
}

let registerApiHandler = (state: state<'ctx>, registration: apiRegistration<'ctx>) => {
  let kind = registration->getApiHandlerKind
  let (path, method) = registration->getApiRegistrationPathAndMethod
  let routeKey = getHtmxRouteKey(method, path)

  switch state.apiHandlersByRoute->Belt.Map.String.get(routeKey) {
  | Some(existingRegistration) =>
    warnDuplicateApiHandler(
      ~incomingKind=kind,
      ~existingKind=existingRegistration->getApiHandlerKind,
      method,
      path,
    )
  | None =>
    state->warnIfApiHandlerIsShadowedByFormAction(~kind, method, path)
    state.apiHandlersByRoute = state.apiHandlersByRoute->Belt.Map.String.set(
      routeKey,
      registration,
    )
  }
}

let getTargetFormActionHandler = (state: state<_>, requestMethod, pathname) =>
  switch requestMethod {
  | GET | POST => state.formActionHandlersByPath->Belt.Map.String.get(pathname)
  | _ => None
  }

let getTargetApiHandler = (state: state<_>, requestMethod, pathname) =>
  state.apiHandlersByRoute->Belt.Map.String.get(getHtmxRouteKey(requestMethod, pathname))

let isCsrfEnabledFor = (state: state<_>, m: method) =>
  switch state.defaultCsrfCheck {
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
  let appendToHead = await requestController.getAppendedHeadContent()
  let appendBeforeBodyEnd = await requestController.getAppendedBeforeBodyEndContent()

  let appendToHead = switch (appendToHead, requestController.getTitleSegments()) {
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

  requestController.getDocHeader() ++ content
}
let defaultHeaders = [("Content-Type", "text/html")]

type responseType = Default | FormActionHandler | HtmxHandler | EndpointHandler

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

type t<'ctx> = {
  useContext: unit => renderConfig<'ctx>,
  handleRequest: handleRequestConfig<'ctx> => promise<Response.t>,
  formAction: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: formActionHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => FormAction.t,
  endpointGet: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => endpointGet,
  endpointGetRef: string => endpointGet,
  endpointGetDefine: 'securityPolicyData. (
    endpointGet,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  endpointPost: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => endpointPost,
  endpointPostRef: string => endpointPost,
  endpointPostDefine: 'securityPolicyData. (
    endpointPost,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  endpointPut: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => endpointPut,
  endpointPutRef: string => endpointPut,
  endpointPutDefine: 'securityPolicyData. (
    endpointPut,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  endpointDelete: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => endpointDelete,
  endpointDeleteRef: string => endpointDelete,
  endpointDeleteDefine: 'securityPolicyData. (
    endpointDelete,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  endpointPatch: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => endpointPatch,
  endpointPatchRef: string => endpointPatch,
  endpointPatchDefine: 'securityPolicyData. (
    endpointPatch,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: endpointHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  hxGet: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => hxGet,
  hxGetRef: string => hxGet,
  hxGetDefine: 'securityPolicyData. (
    hxGet,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  hxPost: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => hxPost,
  hxPostRef: string => hxPost,
  hxPostDefine: 'securityPolicyData. (
    hxPost,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  hxPut: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => hxPut,
  hxPutRef: string => hxPut,
  hxPutDefine: 'securityPolicyData. (
    hxPut,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  hxDelete: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => hxDelete,
  hxDeleteRef: string => hxDelete,
  hxDeleteDefine: 'securityPolicyData. (
    hxDelete,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
  hxPatch: 'securityPolicyData. (
    string,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => hxPatch,
  hxPatchRef: string => hxPatch,
  hxPatchDefine: 'securityPolicyData. (
    hxPatch,
    ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
    ~handler: htmxHandler<'ctx, 'securityPolicyData>,
    ~csrfCheck: bool=?,
  ) => unit,
}

let handleRequestWithState = async (
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

  let targetFormActionHandler = t->getTargetFormActionHandler(request->Request.method, pathname)
  let targetApiHandler = t->getTargetApiHandler(request->Request.method, pathname)

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
    let content = switch (targetFormActionHandler, targetApiHandler) {
    | (Some(_), _) => null
    | (None, None) => await render(renderConfig)
    | (None, Some(HtmxRegistration(reg))) =>
      let csrfEnabled = reg.csrfCheckOpt->Option.getOr(t->isCsrfEnabledFor(reg.method))
      let csrfOk = switch csrfEnabled {
      | true => await CSRF.verifyRequest(request)
      | false => true
      }
      if !csrfOk {
        requestController.setStatus(403)
        string("Invalid CSRF token.")
      } else {
        await reg.run({
          request,
          context: ctx,
          headers,
          requestController,
        })
      }
    | (None, Some(EndpointRegistration(_))) => null
    }

    let responseType = switch (targetFormActionHandler, targetApiHandler) {
    | (Some(_), _) => FormActionHandler
    | (None, Some(HtmxRegistration(_))) => HtmxHandler
    | (None, Some(EndpointRegistration(_))) => EndpointHandler
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

    if targetFormActionHandler->Option.isSome {
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
    } else {
      switch targetApiHandler {
      | Some(EndpointRegistration(reg)) =>
        let csrfEnabled = reg.csrfCheckOpt->Option.getOr(t->isCsrfEnabledFor(reg.method))
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
      | _ if stream =>
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
      | _ =>
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
          requestController.getCurrentRedirect(),
          requestController.getCurrentStatus(),
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
      requestController.setStatus(code->Option.getOr(403))
      string(message->Option.getOr("Not Allowed."))
    }

let makeFormActionRunner: (
  SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  formActionHandler<'ctx, 'securityPolicyData>,
) => responseRunConfig<'ctx> => promise<Response.t> = (securityPolicy, handler) =>
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

let makeEndpointRunner: (
  SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  endpointHandler<'ctx, 'securityPolicyData>,
) => responseRunConfig<'ctx> => promise<Response.t> = (securityPolicy, handler) =>
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

let formAction = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let path = state.formActionHandlerApiPrefix ++ path
  let run = makeFormActionRunner(securityPolicy, handler)
  state->registerFormActionHandler({
    path,
    csrfCheckOpt: csrfCheck,
    run,
  })
  path
}

let getApiPath = (state: state<_>, path) => {
  state.htmxApiPrefix ++ path
}

let registerHtmxPath = (
  state: state<_>,
  ~httpMethod,
  ~path,
  ~securityPolicy,
  ~handler,
  ~csrfCheck=?,
) => {
  let run = makeHtmxRunner(securityPolicy, handler)
  state->registerApiHandler(HtmxRegistration({
    method: httpMethod,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  }))
}

let createHtmxRoute = (state: state<_>, ~httpMethod, path, ~securityPolicy, ~handler, ~csrfCheck=?) => {
  let routePath = state->getApiPath(path)
  state->registerHtmxPath(
    ~httpMethod,
    ~path=routePath,
    ~securityPolicy,
    ~handler,
    ~csrfCheck?,
  )
  routePath
}

let defineHtmxRoute = (state: state<_>, ~httpMethod, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->registerHtmxPath(~httpMethod, ~path, ~securityPolicy, ~handler, ~csrfCheck?)

let registerEndpointPath = (
  state: state<_>,
  ~httpMethod,
  ~path,
  ~securityPolicy,
  ~handler,
  ~csrfCheck=?,
) => {
  let run = makeEndpointRunner(securityPolicy, handler)
  state->registerApiHandler(EndpointRegistration({
    method: httpMethod,
    path,
    csrfCheckOpt: csrfCheck,
    run,
  }))
}

let createEndpointRoute = (
  state: state<_>,
  ~httpMethod,
  path,
  ~securityPolicy,
  ~handler,
  ~csrfCheck=?,
) => {
  let routePath = state->getApiPath(path)
  state->registerEndpointPath(
    ~httpMethod,
    ~path=routePath,
    ~securityPolicy,
    ~handler,
    ~csrfCheck?,
  )
  routePath
}

let defineEndpointRoute = (
  state: state<_>,
  ~httpMethod,
  path,
  ~securityPolicy,
  ~handler,
  ~csrfCheck=?,
) => state->registerEndpointPath(~httpMethod, ~path, ~securityPolicy, ~handler, ~csrfCheck?)

let endpointGet = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createEndpointRoute(~httpMethod=GET, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointGetRef = (state: state<_>, path) => state->getApiPath(path)
let endpointGetDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineEndpointRoute(~httpMethod=GET, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointGetToEndpointURL = s => s

let endpointPost = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createEndpointRoute(~httpMethod=POST, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointPostRef = (state: state<_>, path) => state->getApiPath(path)
let endpointPostDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineEndpointRoute(~httpMethod=POST, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointPostToEndpointURL = s => s

let endpointPut = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createEndpointRoute(~httpMethod=PUT, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointPutRef = (state: state<_>, path) => state->getApiPath(path)
let endpointPutDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineEndpointRoute(~httpMethod=PUT, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointPutToEndpointURL = s => s

let endpointDelete = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createEndpointRoute(~httpMethod=DELETE, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointDeleteRef = (state: state<_>, path) => state->getApiPath(path)
let endpointDeleteDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineEndpointRoute(~httpMethod=DELETE, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointDeleteToEndpointURL = s => s

let endpointPatch = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createEndpointRoute(~httpMethod=PATCH, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointPatchRef = (state: state<_>, path) => state->getApiPath(path)
let endpointPatchDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineEndpointRoute(~httpMethod=PATCH, path, ~securityPolicy, ~handler, ~csrfCheck?)
let endpointPatchToEndpointURL = s => s

let hxGet = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createHtmxRoute(~httpMethod=GET, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxGetRef = (state: state<_>, path) => state->getApiPath(path)
let hxGetDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineHtmxRoute(~httpMethod=GET, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxGetToEndpointURL = s => s

let hxPost = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createHtmxRoute(~httpMethod=POST, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxPostRef = (state: state<_>, path) => state->getApiPath(path)
let hxPostDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineHtmxRoute(~httpMethod=POST, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxPostToEndpointURL = s => s

let hxPut = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createHtmxRoute(~httpMethod=PUT, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxPutRef = (state: state<_>, path) => state->getApiPath(path)
let hxPutDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineHtmxRoute(~httpMethod=PUT, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxPutToEndpointURL = s => s

let hxDelete = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createHtmxRoute(~httpMethod=DELETE, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxDeleteRef = (state: state<_>, path) => state->getApiPath(path)
let hxDeleteDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineHtmxRoute(~httpMethod=DELETE, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxDeleteToEndpointURL = s => s

let hxPatch = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->createHtmxRoute(~httpMethod=PATCH, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxPatchRef = (state: state<_>, path) => state->getApiPath(path)
let hxPatchDefine = (state: state<_>, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  state->defineHtmxRoute(~httpMethod=PATCH, path, ~securityPolicy, ~handler, ~csrfCheck?)
let hxPatchToEndpointURL = s => s

let make = (~requestToContext, ~options=?): t<'ctx> => {
  let state: state<'ctx> = {
    apiHandlersByRoute: Belt.Map.String.empty,
    formActionHandlersByPath: Belt.Map.String.empty,
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

  let useContext = () => state.asyncLocalStorage->AsyncHooks.AsyncLocalStorage.getStoreUnsafe

  let handleRequest = config => state->handleRequestWithState(config)

  {
    useContext,
    handleRequest,
    formAction: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->formAction(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointGet: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointGet(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointGetRef: path => state->endpointGetRef(path),
    endpointGetDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointGetDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointPost: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointPost(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointPostRef: path => state->endpointPostRef(path),
    endpointPostDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointPostDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointPut: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointPut(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointPutRef: path => state->endpointPutRef(path),
    endpointPutDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointPutDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointDelete: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointDelete(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointDeleteRef: path => state->endpointDeleteRef(path),
    endpointDeleteDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointDeleteDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointPatch: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointPatch(path, ~securityPolicy, ~handler, ~csrfCheck?),
    endpointPatchRef: path => state->endpointPatchRef(path),
    endpointPatchDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->endpointPatchDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxGet: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxGet(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxGetRef: path => state->hxGetRef(path),
    hxGetDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxGetDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxPost: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxPost(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxPostRef: path => state->hxPostRef(path),
    hxPostDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxPostDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxPut: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxPut(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxPutRef: path => state->hxPutRef(path),
    hxPutDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxPutDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxDelete: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxDelete(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxDeleteRef: path => state->hxDeleteRef(path),
    hxDeleteDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxDeleteDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxPatch: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxPatch(path, ~securityPolicy, ~handler, ~csrfCheck?),
    hxPatchRef: path => state->hxPatchRef(path),
    hxPatchDefine: (path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
      state->hxPatchDefine(path, ~securityPolicy, ~handler, ~csrfCheck?),
  }
}

@deprecated("Use handler.useContext()")
let useContext = t => t.useContext()

@deprecated("Use handler.handleRequest(...)")
let handleRequest = (t, config) => t.handleRequest(config)

@deprecated("Use handler.formAction(...)")
let formAction = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.formAction(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointGet(...)")
let endpointGet = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointGet(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointGetRef(...)")
let endpointGetRef = (t, path) => t.endpointGetRef(path)

@deprecated("Use handler.endpointGetDefine(...)")
let endpointGetDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointGetDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointPost(...)")
let endpointPost = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointPost(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointPostRef(...)")
let endpointPostRef = (t, path) => t.endpointPostRef(path)

@deprecated("Use handler.endpointPostDefine(...)")
let endpointPostDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointPostDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointPut(...)")
let endpointPut = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointPut(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointPutRef(...)")
let endpointPutRef = (t, path) => t.endpointPutRef(path)

@deprecated("Use handler.endpointPutDefine(...)")
let endpointPutDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointPutDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointDelete(...)")
let endpointDelete = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointDelete(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointDeleteRef(...)")
let endpointDeleteRef = (t, path) => t.endpointDeleteRef(path)

@deprecated("Use handler.endpointDeleteDefine(...)")
let endpointDeleteDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointDeleteDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointPatch(...)")
let endpointPatch = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointPatch(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.endpointPatchRef(...)")
let endpointPatchRef = (t, path) => t.endpointPatchRef(path)

@deprecated("Use handler.endpointPatchDefine(...)")
let endpointPatchDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.endpointPatchDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxGet(...)")
let hxGet = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxGet(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxGetRef(...)")
let hxGetRef = (t, path) => t.hxGetRef(path)

@deprecated("Use handler.hxGetDefine(...)")
let hxGetDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxGetDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxPost(...)")
let hxPost = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxPost(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxPostRef(...)")
let hxPostRef = (t, path) => t.hxPostRef(path)

@deprecated("Use handler.hxPostDefine(...)")
let hxPostDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxPostDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxPut(...)")
let hxPut = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxPut(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxPutRef(...)")
let hxPutRef = (t, path) => t.hxPutRef(path)

@deprecated("Use handler.hxPutDefine(...)")
let hxPutDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxPutDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxDelete(...)")
let hxDelete = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxDelete(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxDeleteRef(...)")
let hxDeleteRef = (t, path) => t.hxDeleteRef(path)

@deprecated("Use handler.hxDeleteDefine(...)")
let hxDeleteDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxDeleteDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxPatch(...)")
let hxPatch = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxPatch(path, ~securityPolicy, ~handler, ~csrfCheck?)

@deprecated("Use handler.hxPatchRef(...)")
let hxPatchRef = (t, path) => t.hxPatchRef(path)

@deprecated("Use handler.hxPatchDefine(...)")
let hxPatchDefine = (t, path, ~securityPolicy, ~handler, ~csrfCheck=?) =>
  t.hxPatchDefine(path, ~securityPolicy, ~handler, ~csrfCheck?)
