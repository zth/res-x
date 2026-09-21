type state = {
  mutable status: int,
  mutable redirect: option<(string, option<int>)>,
  mutable docHeader: option<string>,
  mutable headContent: option<array<Jsx.element>>,
  mutable bodyEndContent: option<array<Jsx.element>>,
  mutable titleSegments: option<array<string>>,
}

type t = {
  setStatus: int => unit,
  redirect: (string, ~status: int=?) => Jsx.element,
  getCurrentStatus: unit => int,
  getCurrentRedirect: unit => option<(string, option<int>)>,
  getTitleSegments: unit => array<string>,
  getDocHeader: unit => string,
  setDocHeader: option<string> => unit,
  appendToHead: Jsx.element => unit,
  getAppendedHeadContent: unit => promise<option<string>>,
  appendBeforeBodyEnd: Jsx.element => unit,
  getAppendedBeforeBodyEndContent: unit => promise<option<string>>,
  appendTitleSegment: string => unit,
  prependTitleSegment: string => unit,
  setFullTitle: string => unit,
}

@val external null: Jsx.element = "null"
external array: array<Jsx.element> => Jsx.element = "%identity"

// Most requests never append metadata. Allocate each collection on first use.
let append = (items, item) => switch items {
| None => [item]
| Some(items) => {
    items->Array.push(item)
    items
  }
}

let make = (): t => {
  let state: state = {
    status: 200,
    redirect: None,
    headContent: None,
    bodyEndContent: None,
    titleSegments: None,
    docHeader: Some("<!DOCTYPE html>"),
  }

  {
    setStatus: status => state.status = status,
    redirect: (url, ~status=?) => {
      state.redirect = Some((url, status))
      null
    },
    getCurrentStatus: () => state.status,
    getCurrentRedirect: () => state.redirect,
    getTitleSegments: () => switch state.titleSegments {
    | None => []
    | Some(segments) => segments->Array.copy
    },
    getDocHeader: () => state.docHeader->Option.getOr(""),
    setDocHeader: docHeader => state.docHeader = docHeader,
    appendToHead: content => state.headContent = Some(append(state.headContent, content)),
    appendBeforeBodyEnd: content => state.bodyEndContent = Some(append(state.bodyEndContent, content)),
    appendTitleSegment: segment => state.titleSegments = Some(append(state.titleSegments, segment)),
    prependTitleSegment: segment => switch state.titleSegments {
    | None => state.titleSegments = Some([segment])
    | Some(segments) => segments->Array.unshift(segment)
    },
    setFullTitle: title => state.titleSegments = Some([title]),
    getAppendedHeadContent: async () =>
      switch state.headContent {
      | None => None
      | Some(headContent) => Some(await headContent->array->H.renderToString)
      },
    getAppendedBeforeBodyEndContent: async () =>
      switch state.bodyEndContent {
      | None => None
      | Some(bodyEndContent) => Some(await bodyEndContent->array->H.renderToString)
      },
  }
}

@deprecated("Use requestController.setStatus(...)")
let setStatus = (t, status) => t.setStatus(status)

@deprecated("Use requestController.redirect(...)")
let redirect = (t, url, ~status=?) => t.redirect(url, ~status?)

@deprecated("Use requestController.getCurrentStatus()")
let getCurrentStatus = t => t.getCurrentStatus()

@deprecated("Use requestController.getCurrentRedirect()")
let getCurrentRedirect = t => t.getCurrentRedirect()

@deprecated("Use requestController.getTitleSegments()")
let getTitleSegments = t => t.getTitleSegments()

@deprecated("Use requestController.getDocHeader()")
let getDocHeader = t => t.getDocHeader()

@deprecated("Use requestController.setDocHeader(...)")
let setDocHeader = (t, docHeader) => t.setDocHeader(docHeader)

@deprecated("Use requestController.appendToHead(...)")
let appendToHead = (t, content) => t.appendToHead(content)

@deprecated("Use requestController.getAppendedHeadContent()")
let getAppendedHeadContent = t => t.getAppendedHeadContent()

@deprecated("Use requestController.appendBeforeBodyEnd(...)")
let appendBeforeBodyEnd = (t, content) => t.appendBeforeBodyEnd(content)

@deprecated("Use requestController.getAppendedBeforeBodyEndContent()")
let getAppendedBeforeBodyEndContent = t => t.getAppendedBeforeBodyEndContent()

@deprecated("Use requestController.appendTitleSegment(...)")
let appendTitleSegment = (t, segment) => t.appendTitleSegment(segment)

@deprecated("Use requestController.prependTitleSegment(...)")
let prependTitleSegment = (t, segment) => t.prependTitleSegment(segment)

@deprecated("Use requestController.setFullTitle(...)")
let setFullTitle = (t, title) => t.setFullTitle(title)
