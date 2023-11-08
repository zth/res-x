type htmxHandlerConfig<'ctx> = {
  request: Bun.Request.t,
  context: 'ctx,
  headers: Bun.Headers.t,
  requestController: ResX__RequestController.t,
}

type htmxHandler<'ctx> = htmxHandlerConfig<'ctx> => promise<Jsx.element>

type t<'ctx>

type hxGet
type hxPost
type hxPut
type hxPatch
type hxDelete

let make: (~requestToContext: Bun.Request.t => promise<'ctx>) => t<'ctx>

let get: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxGet
let makeGet: string => hxGet
let implementGet: (t<'ctx>, hxGet, ~handler: htmxHandler<'ctx>) => unit

let post: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxPost
let makePost: string => hxPost
let implementPost: (t<'ctx>, hxPost, ~handler: htmxHandler<'ctx>) => unit

let put: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxPut
let makePut: string => hxPut
let implementPut: (t<'ctx>, hxPut, ~handler: htmxHandler<'ctx>) => unit

let delete: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxDelete
let makeDelete: string => hxDelete
let implementDelete: (t<'ctx>, hxDelete, ~handler: htmxHandler<'ctx>) => unit

let patch: (t<'ctx>, string, ~handler: htmxHandler<'ctx>) => hxPatch
let makePatch: string => hxPatch
let implementPatch: (t<'ctx>, hxPatch, ~handler: htmxHandler<'ctx>) => unit

type renderConfig<'ctx> = {
  request: Bun.Request.t,
  headers: Bun.Headers.t,
  context: 'ctx,
  path: list<string>,
  url: Bun.URL.t,
  requestController: ResX__RequestController.t,
}

let useContext: t<'ctx> => renderConfig<'ctx>

type handleRequestConfig<'ctx> = {
  request: Bun.Request.t,
  server: Bun.Server.t,
  render: renderConfig<'ctx> => promise<Jsx.element>,
  setupHeaders?: unit => Bun.Headers.t,
  renderTitle?: array<string> => string,
  experimental_stream?: bool,
}

let handleRequest: (t<'ctx>, handleRequestConfig<'ctx>) => promise<Bun.Response.t>

module Internal: {
  let getHandlers: t<'ctx> => array<(Bun.method, string, htmxHandler<'ctx>)>
}
