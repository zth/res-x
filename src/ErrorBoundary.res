@@jsxConfig({module_: "Hjsx"})

@module("./vendor/hyperons.js")
external createContext: ('context, @as("errorBoundary") _) => H.Context.t<'context> =
  "createContext"

type errorFn = JsExn.t => Jsx.element

let context = createContext(None)

module Provider = {
  let make = H.Context.provider(context)
}

@jsx.component
let make = (~children, ~renderError: errorFn) => {
  <Provider value={Some(renderError)}> {children} </Provider>
}
