open ResXJsx

/** Function called when an error occurs. Expected to return the fallback JSX for the error. */
type errorFn = Exn.t => Jsx.element

@react.component
let make: (~children: Jsx.element, ~renderError: errorFn) => Jsx.element
