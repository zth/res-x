type t = {
  mutable status: int,
  mutable redirect: option<(string, option<int>)>,
  mutable docHeader: option<string>,
  headContent: array<Jsx.element>,
  titleSegments: array<string>,
}
let make = () => {
  status: 200,
  redirect: None,
  headContent: [],
  titleSegments: [],
  docHeader: Some("<!DOCTYPE html>"),
}
let setStatus = (t, status) => t.status = status

@val external null: Jsx.element = "null"
external array: array<Jsx.element> => Jsx.element = "%identity"

let redirect = (t, url, ~status=?) => {
  t.redirect = Some((url, status))
  null
}
let getCurrentStatus = t => t.status
let getCurrentRedirect = t => t.redirect
let getTitleSegments = t => t.titleSegments->Array.copy
let getDocHeader = t => t.docHeader->Option.getOr("")
let setDocHeader = (t, docHeader) => t.docHeader = docHeader
let appendToHead = (t, content) => t.headContent->Array.push(content)
let appendTitleSegment = (t, segment) => t.titleSegments->Array.push(segment)
let setFullTitle = (t, title) =>
  t.titleSegments->Array.splice(~insert=[title], ~start=0, ~remove={t.titleSegments->Array.length})
let getAppendedHeadContent = async (t): option<string> =>
  switch t.headContent {
  | [] => None
  | headContent => Some(await headContent->array->H.renderToString)
  }
