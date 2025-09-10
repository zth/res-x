module FormAction: {
  type t
  let string: string => t
  /** Returns the actual endpoint URL string for this form action. Most of the time you should pass the FormAction.t directly to form elements instead of using this. */
  let toEndpointURL: t => string
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

type t<'ctx>

type hxGet
type hxPost
type hxPut
type hxPatch
type hxDelete

type options = {
  /** 
   Prefix for the API routes of any HTMX handlers. 
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
}

let make: (~requestToContext: Request.t => promise<'ctx>, ~options: options=?) => t<'ctx>

/** 
 Creates a form action that you can then attach to a form.

 ## Example
 ```rescript
 let onSubmit = Handler.handler->ResX.Handlers.formAction("/user-submitted", ~securityPolicy=ResX.SecurityPolicy.allow, ~handler=async _ => {
  Response.makeRedirect("/some-other-page")
 })

 <form action=onSubmit>
 </form>
 ```
 */
let formAction: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: formActionHandler<'ctx>,
) => FormAction.t

let hxGet: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxGet
let hxGetRef: (t<_>, string) => hxGet
let hxGetDefine: (
  t<'ctx>,
  hxGet,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit
/** Returns the actual endpoint URL string for this hxGet handler. Most of the time you should pass the hxGet directly to HTMX attributes instead of using this. */
let hxGetToEndpointURL: hxGet => string

let hxPost: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxPost
let hxPostRef: (t<_>, string) => hxPost
let hxPostDefine: (
  t<'ctx>,
  hxPost,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit
/** Returns the actual endpoint URL string for this hxPost handler. Most of the time you should pass the hxPost directly to HTMX attributes instead of using this. */
let hxPostToEndpointURL: hxPost => string

let hxPut: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxPut
let hxPutRef: (t<_>, string) => hxPut
let hxPutDefine: (
  t<'ctx>,
  hxPut,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit
/** Returns the actual endpoint URL string for this hxPut handler. Most of the time you should pass the hxPut directly to HTMX attributes instead of using this. */
let hxPutToEndpointURL: hxPut => string

let hxDelete: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxDelete
let hxDeleteRef: (t<_>, string) => hxDelete
let hxDeleteDefine: (
  t<'ctx>,
  hxDelete,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit
/** Returns the actual endpoint URL string for this hxDelete handler. Most of the time you should pass the hxDelete directly to HTMX attributes instead of using this. */
let hxDeleteToEndpointURL: hxDelete => string

let hxPatch: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxPatch
let hxPatchRef: (t<_>, string) => hxPatch
let hxPatchDefine: (
  t<'ctx>,
  hxPatch,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit
/** Returns the actual endpoint URL string for this hxPatch handler. Most of the time you should pass the hxPatch directly to HTMX attributes instead of using this. */
let hxPatchToEndpointURL: hxPatch => string

type renderConfig<'ctx> = {
  request: Request.t,
  headers: Headers.t,
  context: 'ctx,
  path: list<string>,
  url: URL.t,
  requestController: RequestController.t,
}

let useContext: t<'ctx> => renderConfig<'ctx>

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

type handleRequestConfig<'ctx> = {
  request: Request.t,
  render: renderConfig<'ctx> => promise<Jsx.element>,
  setupHeaders?: unit => Headers.t,
  renderTitle?: array<string> => string,
  experimental_stream?: bool,
  onBeforeSendResponse?: onBeforeSendResponse<'ctx> => promise<Response.t>,
  onBeforeBuildResponse?: onBeforeBuildResponse<'ctx> => promise<unit>,
}

let handleRequest: (t<'ctx>, handleRequestConfig<'ctx>) => promise<Response.t>

module Internal: {
  let getHandlers: t<'ctx> => array<(
    method,
    string,
    SecurityPolicy.handler<'ctx>,
    htmxHandler<'ctx>,
  )>
}
