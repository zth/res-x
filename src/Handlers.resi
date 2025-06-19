module FormAction: {
  type t
  let string: string => t
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
let makeHxGetIdentifier: (t<_>, string) => hxGet
let implementHxGetIdentifier: (
  t<'ctx>,
  hxGet,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit

let hxPost: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxPost
let makeHxPostIdentifier: (t<_>, string) => hxPost
let implementHxPostIdentifier: (
  t<'ctx>,
  hxPost,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit

let hxPut: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxPut
let makeHxPutIdentifier: (t<_>, string) => hxPut
let implementHxPutIdentifier: (
  t<'ctx>,
  hxPut,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit

let hxDelete: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxDelete
let makeHxDeleteIdentifier: (t<_>, string) => hxDelete
let implementHxDeleteIdentifier: (
  t<'ctx>,
  hxDelete,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit

let hxPatch: (
  t<'ctx>,
  string,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => hxPatch
let makeHxPatchIdentifier: (t<_>, string) => hxPatch
let implementHxPatchIdentifier: (
  t<'ctx>,
  hxPatch,
  ~securityPolicy: SecurityPolicy.handler<'ctx>,
  ~handler: htmxHandler<'ctx>,
) => unit

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
