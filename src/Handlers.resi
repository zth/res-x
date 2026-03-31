module FormAction: {
  type t
  let string: string => t
  /** Returns the actual endpoint URL string for this form action. Most of the time you should pass the FormAction.t directly to form elements instead of using this. */
  let toEndpointURL: t => string
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

type hxGet
type hxPost
type hxPut
type hxPatch
type hxDelete
type endpointGet
type endpointPost
type endpointPut
type endpointPatch
type endpointDelete

type defaultCsrfCheck =
  | ForAllMethods(bool)
  | PerMethod({
      get: option<bool>,
      post: option<bool>,
      put: option<bool>,
      patch: option<bool>,
      delete: option<bool>,
    })

type options = {
  /** 
   Prefix for the API routes of any HTMX handlers and regular endpoints. 
   This is opaque to your code, and serves as a guard against accidentally overwriting other routes with your handlers.

   @default "/_api"
   */
  htmxApiPrefix?: string,
  /** 
   Prefix for the API routes of any form action handlers. 
   This is opaque to your code, and serves as a guard against accidentally overwriting other routes with your handlers.

  @default "/_form"
   */
  formActionHandlerApiPrefix?: string,
  /**
   Default CSRF checking for handlers. Either one boolean for all methods
   or per-method configuration. Can be overridden per handler via `~csrfCheck`.

   @default ForAllMethods(false)
   */
  defaultCsrfCheck?: defaultCsrfCheck,
}

type renderConfig<'ctx> = {
  request: Request.t,
  headers: Headers.t,
  context: 'ctx,
  path: list<string>,
  url: URL.t,
  requestController: RequestController.t,
}

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

let make: (~requestToContext: Request.t => promise<'ctx>, ~options: options=?) => t<'ctx>

/** 
 Creates a form action that you can then attach to a form.

 ## Example
 ```rescript
 let onSubmit = Handler.handler.formAction("/user-submitted", ~securityPolicy=ResX.SecurityPolicy.allow, ~handler=async _ => {
  Response.makeRedirect("/some-other-page")
 })

 <form action=onSubmit>
 </form>
 ```
 */
@deprecated("Use handler.formAction(...)")
let formAction: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: formActionHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => FormAction.t

@deprecated("Use handler.endpointGet(...)")
let endpointGet: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => endpointGet
@deprecated("Use handler.endpointGetRef(...)")
let endpointGetRef: (t<_>, string) => endpointGet
@deprecated("Use handler.endpointGetDefine(...)")
let endpointGetDefine: (
  t<'ctx>,
  endpointGet,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this endpointGet handler. Most of the time you should pass the endpointGet directly to the client code that needs it instead of extracting the URL. */
let endpointGetToEndpointURL: endpointGet => string

@deprecated("Use handler.endpointPost(...)")
let endpointPost: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => endpointPost
@deprecated("Use handler.endpointPostRef(...)")
let endpointPostRef: (t<_>, string) => endpointPost
@deprecated("Use handler.endpointPostDefine(...)")
let endpointPostDefine: (
  t<'ctx>,
  endpointPost,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this endpointPost handler. Most of the time you should pass the endpointPost directly to the client code that needs it instead of extracting the URL. */
let endpointPostToEndpointURL: endpointPost => string

@deprecated("Use handler.endpointPut(...)")
let endpointPut: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => endpointPut
@deprecated("Use handler.endpointPutRef(...)")
let endpointPutRef: (t<_>, string) => endpointPut
@deprecated("Use handler.endpointPutDefine(...)")
let endpointPutDefine: (
  t<'ctx>,
  endpointPut,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this endpointPut handler. Most of the time you should pass the endpointPut directly to the client code that needs it instead of extracting the URL. */
let endpointPutToEndpointURL: endpointPut => string

@deprecated("Use handler.endpointDelete(...)")
let endpointDelete: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => endpointDelete
@deprecated("Use handler.endpointDeleteRef(...)")
let endpointDeleteRef: (t<_>, string) => endpointDelete
@deprecated("Use handler.endpointDeleteDefine(...)")
let endpointDeleteDefine: (
  t<'ctx>,
  endpointDelete,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this endpointDelete handler. Most of the time you should pass the endpointDelete directly to the client code that needs it instead of extracting the URL. */
let endpointDeleteToEndpointURL: endpointDelete => string

@deprecated("Use handler.endpointPatch(...)")
let endpointPatch: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => endpointPatch
@deprecated("Use handler.endpointPatchRef(...)")
let endpointPatchRef: (t<_>, string) => endpointPatch
@deprecated("Use handler.endpointPatchDefine(...)")
let endpointPatchDefine: (
  t<'ctx>,
  endpointPatch,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: endpointHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this endpointPatch handler. Most of the time you should pass the endpointPatch directly to the client code that needs it instead of extracting the URL. */
let endpointPatchToEndpointURL: endpointPatch => string

@deprecated("Use handler.hxGet(...)")
let hxGet: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => hxGet
@deprecated("Use handler.hxGetRef(...)")
let hxGetRef: (t<_>, string) => hxGet
@deprecated("Use handler.hxGetDefine(...)")
let hxGetDefine: (
  t<'ctx>,
  hxGet,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this hxGet handler. Most of the time you should pass the hxGet directly to HTMX attributes instead of using this. */
let hxGetToEndpointURL: hxGet => string

@deprecated("Use handler.hxPost(...)")
let hxPost: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => hxPost
@deprecated("Use handler.hxPostRef(...)")
let hxPostRef: (t<_>, string) => hxPost
@deprecated("Use handler.hxPostDefine(...)")
let hxPostDefine: (
  t<'ctx>,
  hxPost,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this hxPost handler. Most of the time you should pass the hxPost directly to HTMX attributes instead of using this. */
let hxPostToEndpointURL: hxPost => string

@deprecated("Use handler.hxPut(...)")
let hxPut: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => hxPut
@deprecated("Use handler.hxPutRef(...)")
let hxPutRef: (t<_>, string) => hxPut
@deprecated("Use handler.hxPutDefine(...)")
let hxPutDefine: (
  t<'ctx>,
  hxPut,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this hxPut handler. Most of the time you should pass the hxPut directly to HTMX attributes instead of using this. */
let hxPutToEndpointURL: hxPut => string

@deprecated("Use handler.hxDelete(...)")
let hxDelete: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => hxDelete
@deprecated("Use handler.hxDeleteRef(...)")
let hxDeleteRef: (t<_>, string) => hxDelete
@deprecated("Use handler.hxDeleteDefine(...)")
let hxDeleteDefine: (
  t<'ctx>,
  hxDelete,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this hxDelete handler. Most of the time you should pass the hxDelete directly to HTMX attributes instead of using this. */
let hxDeleteToEndpointURL: hxDelete => string

@deprecated("Use handler.hxPatch(...)")
let hxPatch: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => hxPatch
@deprecated("Use handler.hxPatchRef(...)")
let hxPatchRef: (t<_>, string) => hxPatch
@deprecated("Use handler.hxPatchDefine(...)")
let hxPatchDefine: (
  t<'ctx>,
  hxPatch,
  ~securityPolicy: SecurityPolicy.handler<'ctx, 'securityPolicyData>,
  ~handler: htmxHandler<'ctx, 'securityPolicyData>,
  ~csrfCheck: bool=?,
) => unit
/** Returns the actual endpoint URL string for this hxPatch handler. Most of the time you should pass the hxPatch directly to HTMX attributes instead of using this. */
let hxPatchToEndpointURL: hxPatch => string

@deprecated("Use handler.useContext()")
let useContext: t<'ctx> => renderConfig<'ctx>

@deprecated("Use handler.handleRequest(...)")
let handleRequest: (t<'ctx>, handleRequestConfig<'ctx>) => promise<Response.t>
