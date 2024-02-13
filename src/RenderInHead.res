@jsx.component
let make = (~children, ~requestController) => {
  requestController->RequestController.appendToHead(children)
  Hjsx.null
}
