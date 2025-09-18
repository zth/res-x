type t
let make: unit => t
let setStatus: (t, int) => unit
let redirect: (t, string, ~status: int=?) => Jsx.element
let getCurrentStatus: t => int
let getCurrentRedirect: t => option<(string, option<int>)>
let getTitleSegments: t => array<string>
let getDocHeader: t => string
let appendToHead: (t, Jsx.element) => unit
let getAppendedHeadContent: t => promise<option<string>>
let appendBeforeBodyEnd: (t, Jsx.element) => unit
let getAppendedBeforeBodyEndContent: t => promise<option<string>>
let appendTitleSegment: (t, string) => unit
let prependTitleSegment: (t, string) => unit
let setFullTitle: (t, string) => unit
let setDocHeader: (t, option<string>) => unit
