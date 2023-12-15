type htmxHandlerConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
  headers: Headers.t,
  requestController: RequestController.t,
}

type htmxHandler<'ctx> = htmxHandlerConfig<'ctx> => promise<Jsx.element>

type t<'ctx>

type hxGet
type hxPost
type hxPut
type hxPatch
type hxDelete

let make: (~requestToContext: Request.t => promise<'ctx>) => t<'ctx>

let hxGet: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxGet
let makeHxGetIdentifier: string => hxGet
let implementHxGetIdentifier: (t<'ctx>, hxGet, ~handler: htmxHandler<'ctx>) => unit

let hxPost: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxPost
let makeHxPostIdentifier: string => hxPost
let implementHxPostIdentifier: (t<'ctx>, hxPost, ~handler: htmxHandler<'ctx>) => unit

let hxPut: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxPut
let makeHxPutIdentifier: string => hxPut
let implementHxPutIdentifier: (t<'ctx>, hxPut, ~handler: htmxHandler<'ctx>) => unit

let hxDelete: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxDelete
let makeHxDeleteIdentifier: string => hxDelete
let implementHxDeleteIdentifier: (t<'ctx>, hxDelete, ~handler: htmxHandler<'ctx>) => unit

let hxPatch: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxPatch
let makeHxPatchIdentifier: string => hxPatch
let implementHxPatchIdentifier: (t<'ctx>, hxPatch, ~handler: htmxHandler<'ctx>) => unit

type renderConfig<'ctx> = {
  request: Request.t,
  headers: Headers.t,
  context: 'ctx,
  path: list<string>,
  url: URL.t,
  requestController: RequestController.t,
}

let useContext: t<'ctx> => renderConfig<'ctx>

type handleRequestConfig<'ctx> = {
  request: Request.t,
  render: renderConfig<'ctx> => promise<Jsx.element>,
  setupHeaders?: unit => Headers.t,
  renderTitle?: array<string> => string,
  experimental_stream?: bool,
}

let handleRequest: (t<'ctx>, handleRequestConfig<'ctx>) => promise<Response.t>

module Internal: {
  let getHandlers: t<'ctx> => array<(method, string, htmxHandler<'ctx>)>
}
