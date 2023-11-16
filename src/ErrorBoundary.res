module React = ResX__React

@module("./vendor/hyperons.js")
external createContext: ('context, @as("errorBoundary") _) => H.Context.t<'context> =
  "createContext"

type errorFn = Exn.t => Jsx.element

let context = createContext(None)

module Provider = {
  let make = H.Context.provider(context)
}

@react.component
let make = (~children, ~renderError: errorFn) => {
  <Provider value={Some(renderError)}> {children} </Provider>
}
