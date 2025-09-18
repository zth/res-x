@jsx.component
let make = (~children, ~requestController) => {
  requestController->RequestController.appendBeforeBodyEnd(children)
  Hjsx.null
}
