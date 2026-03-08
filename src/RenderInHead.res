@jsx.component
let make = (~children, ~requestController: RequestController.t) => {
  requestController.appendToHead(children)
  Hjsx.null
}
