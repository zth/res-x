type state = {
  mutable status: int,
  mutable redirect: option<(string, option<int>)>,
  mutable docHeader: option<string>,
  headContent: array<Jsx.element>,
  bodyEndContent: array<Jsx.element>,
  titleSegments: array<string>,
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

let make = (): t => {
  let state: state = {
    status: 200,
    redirect: None,
    headContent: [],
    bodyEndContent: [],
    titleSegments: [],
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
    getTitleSegments: () => state.titleSegments->Array.copy,
    getDocHeader: () => state.docHeader->Option.getOr(""),
    setDocHeader: docHeader => state.docHeader = docHeader,
    appendToHead: content => state.headContent->Array.push(content),
    appendBeforeBodyEnd: content => state.bodyEndContent->Array.push(content),
    appendTitleSegment: segment => state.titleSegments->Array.push(segment),
    prependTitleSegment: segment => state.titleSegments->Array.unshift(segment),
    setFullTitle: title =>
      state.titleSegments->Array.splice(~insert=[title], ~start=0, ~remove={state.titleSegments->Array.length}),
    getAppendedHeadContent: async () =>
      switch state.headContent {
      | [] => None
      | headContent => Some(await headContent->array->H.renderToString)
      },
    getAppendedBeforeBodyEndContent: async () =>
      switch state.bodyEndContent {
      | [] => None
      | bodyEndContent => Some(await bodyEndContent->array->H.renderToString)
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
