type hxSwap =
  | @as("outerHTML") OuterHTML
  | @as("innerHTML") InnerHTML
  | @as("beforebegin") BeforeBegin
  | @as("afterbegin") AfterBegin
  | @as("beforeend") BeforeEnd
  | @as("afterend") AfterEnd
  | @as("delete") Delete
  | @as("none") None

type topOrBottom = | @as("top") Top | @as("bottom") Bottom

type modifier =
  | Swap(string)
  | Settle(string)
  | Transition
  | Scroll(topOrBottom)
  | ScrollWithSelector(string, topOrBottom)
  | Show(topOrBottom)
  | ShowWithSelector(string, topOrBottom)

module Swap: {
  type t
  let make: (hxSwap, ~modifier: modifier=?) => t
}

type hxTarget =
  | CssSelector(string)
  | This
  | Closest({cssSelector: string})
  | Find({cssSelector: string})
  | Next({cssSelector: string})
  | Previous({cssSelector: string})

module Target: {
  type t
  let make: hxTarget => t
}

@unboxed type hxUrl = | @as(true) True | @as(false) False | URL(string)

type hxParams = IncludeAll | IncludeNone | Not(array<string>) | Only(array<string>)

module Params: {
  type t
  let make: hxParams => t
}

type hxEncoding = MultipartFormData

module Encoding: {
  type t
  let make: hxEncoding => t
}

type hxIndicator = Selector(string) | Closest(string)

module Indicator: {
  type t
  let make: hxIndicator => t
}

module Headers: {
  type t
  let make: RescriptCore.Dict.t<string> => t
}

type hxSyncStrategyQueueModifier =
  | /** queue the first request to show up while a request is in flight */
  @as("first")
  First
  | /** queue the last request to show up while a request is in flight */
  @as("last")
  Last
  | /** queue all requests that show up while a request is in flight */
  @as("all")
  All

type hxSyncStrategy =
  | Drop
  | Abort
  | Replace
  | Queue
  | QueueWithModifier(hxSyncStrategyQueueModifier)

type hxSync = Selector(string) | SelectorAndStrategy(string, hxSyncStrategy)

module Sync: {
  type t
  let make: hxSync => t
}

type hxVals = Json(Js.Json.t) | JsonUnsafe(string) | RawJavaScript(string)

module Vals: {
  type t
  let make: hxVals => t
}

type hxInheritedAttributes =
  | @as("hx-swap") Swap
  | @as("hx-boost") Boost
  | @as("hx-push-url") PushUrl
  | @as("hx-replace-url") ReplaceUrl
  | @as("hx-select") Select
  | @as("hx-select-oob") SelectOob
  | @as("hx-params") Params
  | @as("hx-prompt") Prompt
  | @as("hx-validate") Validate
  | @as("hx-confirm") Confirm
  | @as("hx-disable") Disable
  | @as("hx-encoding") Encoding
  | @as("hx-indicator") Indicator
  | @as("hx-history") History
  | @as("hx-history-elt") HistoryElt
  | @as("hx-include") Include
  | @as("hx-headers") Headers
  | @as("hx-sync") Sync
  | @as("hx-vals") Vals
  | @as("hx-preserve") Preserve

type hxDisinherit = All | Attributes(array<hxInheritedAttributes>)

module Disinherit: {
  type t
  let make: hxDisinherit => t
}

type htmxProps = {
  /** https://htmx.org/attributes/hx-get/ */
  @as("hx-get")
  hxGet?: Handlers.hxGet,
  @as("data-hx-get")
  rawHxGet?: string,
  /** https://htmx.org/attributes/hx-post/ */
  @as("hx-post")
  hxPost?: Handlers.hxPost,
  @as("data-hx-post")
  rawHxPost?: string,
  /** https://htmx.org/attributes/hx-put/ */
  @as("hx-put")
  hxPut?: Handlers.hxPut,
  @as("data-hx-put")
  rawHxPut?: string,
  /** https://htmx.org/attributes/hx-delete/ */
  @as("hx-delete")
  hxDelete?: Handlers.hxDelete,
  @as("data-hx-delete")
  rawHxDelete?: string,
  /** https://htmx.org/attributes/hx-patch/ */
  @as("hx-patch")
  hxPatch?: Handlers.hxPatch,
  @as("data-hx-patch")
  rawHxPatch?: string,
  /** https://htmx.org/attributes/hx-swap/ */
  @as("hx-swap")
  hxSwap?: Swap.t,
  @as("data-hx-swap")
  rawHxSwap?: string,
  /** https://htmx.org/docs/#boosting */
  @as("hx-boost")
  hxBoost?: bool,
  /** https://htmx.org/attributes/hx-push-url/ */
  @as("hx-push-url")
  hxPushUrl?: hxUrl,
  @as("data-hx-push-url")
  rawHxPushUrl?: string,
  /** https://htmx.org/attributes/hx-replace-url/ */
  @as("hx-replace-url")
  hxReplaceUrl?: hxUrl,
  @as("data-hx-replace-url")
  rawHxReplaceUrl?: string,
  /** https://htmx.org/attributes/hx-select/ */
  @as("hx-select")
  hxSelect?: string,
  @as("data-hx-select")
  rawHxSelect?: string,
  /** https://htmx.org/attributes/hx-select-oob/ */
  @as("hx-select-oob")
  hxSelectOob?: string,
  @as("data-hx-select-oob")
  rawHxSelectOob?: string,
  /** https://htmx.org/attributes/hx-params/ */
  @as("hx-params")
  hxParams?: Params.t,
  @as("data-hx-params")
  rawHxParams?: string,
  /** https://htmx.org/attributes/hx-prompt/ */
  @as("hx-prompt")
  hxPrompt?: string,
  @as("data-hx-prompt")
  rawHxPrompt?: string,
  /** https://htmx.org/attributes/hx-validate/ */
  @as("hx-validate")
  hxValidate?: bool,
  /** https://htmx.org/attributes/hx-confirm/ */
  @as("hx-confirm")
  hxConfirm?: string,
  /** https://htmx.org/attributes/hx-disable/ */
  @as("hx-disable")
  hxDisable?: bool,
  /** https://htmx.org/attributes/hx-encoding/ */
  @as("hx-encoding")
  hxEncoding?: Encoding.t,
  @as("data-hx-encoding")
  rawHxEncoding?: string,
  /** https://htmx.org/attributes/hx-indicator/ */
  @as("hx-indicator")
  hxIndicator?: Indicator.t,
  @as("data-hx-indicator")
  rawHxIndicator?: string,
  /** https://htmx.org/attributes/hx-history/ */
  @as("hx-history")
  hxHistory?: bool,
  /** https://htmx.org/attributes/hx-history-elt/ */
  @as("hx-history-elt")
  hxHistoryElt?: bool,
  /** https://htmx.org/attributes/hx-include/ */
  @as("hx-include")
  hxInclude?: string,
  /** https://htmx.org/attributes/hx-headers/ */
  @as("hx-headers")
  hxHeaders?: Headers.t,
  @as("data-hx-headers")
  rawHxHeaders?: string,
  /** https://htmx.org/attributes/hx-sync/ */
  @as("hx-sync")
  hxSync?: Sync.t,
  @as("data-hx-sync")
  rawHxSync?: string,
  /** https://htmx.org/attributes/hx-vals/ */
  @as("hx-vals")
  hxVals?: Vals.t,
  @as("data-hx-vals")
  rawHxVals?: string,
  /** https://htmx.org/attributes/hx-preserve/ */
  @as("hx-preserve")
  hxPreserve?: bool,
  /** https://htmx.org/attributes/hx-disinherit/ */
  @as("hx-disinherit")
  hxDisinherit?: Disinherit.t,
  @as("data-hx-disinherit")
  rawHxDisinherit?: string,
  /** https://htmx.org/attributes/hx-target/  TODO */
  @as("hx-target")
  hxTarget?: Target.t,
  @as("data-hx-target")
  rawHxTarget?: string,
  /** https://htmx.org/attributes/hx-trigger/ */
  @as("hx-trigger")
  hxTrigger?: string, // TODO: Bind to something more elaborate
  @as("data-hx-trigger")
  rawHxTrigger?: string,
}
