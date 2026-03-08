@jsx.component
let make = (~children, ~requestController: RequestController.t) => {
  requestController.appendBeforeBodyEnd(children)
  Hjsx.null
}
