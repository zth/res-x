@@jsxConfig({module_: "Hjsx"})

/** Function called when an error occurs. Expected to return the fallback JSX for the error. */
type errorFn = Exn.t => Hjsx.element

@jsx.component
let make: (~children: Hjsx.element, ~renderError: errorFn) => Hjsx.element
