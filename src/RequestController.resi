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
let make: unit => t

@deprecated("Use requestController.setStatus(...)")
let setStatus: (t, int) => unit

@deprecated("Use requestController.redirect(...)")
let redirect: (t, string, ~status: int=?) => Jsx.element

@deprecated("Use requestController.getCurrentStatus()")
let getCurrentStatus: t => int

@deprecated("Use requestController.getCurrentRedirect()")
let getCurrentRedirect: t => option<(string, option<int>)>

@deprecated("Use requestController.getTitleSegments()")
let getTitleSegments: t => array<string>

@deprecated("Use requestController.getDocHeader()")
let getDocHeader: t => string

@deprecated("Use requestController.appendToHead(...)")
let appendToHead: (t, Jsx.element) => unit

@deprecated("Use requestController.getAppendedHeadContent()")
let getAppendedHeadContent: t => promise<option<string>>

@deprecated("Use requestController.appendBeforeBodyEnd(...)")
let appendBeforeBodyEnd: (t, Jsx.element) => unit

@deprecated("Use requestController.getAppendedBeforeBodyEndContent()")
let getAppendedBeforeBodyEndContent: t => promise<option<string>>

@deprecated("Use requestController.appendTitleSegment(...)")
let appendTitleSegment: (t, string) => unit

@deprecated("Use requestController.prependTitleSegment(...)")
let prependTitleSegment: (t, string) => unit

@deprecated("Use requestController.setFullTitle(...)")
let setFullTitle: (t, string) => unit

@deprecated("Use requestController.setDocHeader(...)")
let setDocHeader: (t, option<string>) => unit
