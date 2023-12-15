@react.component
let make = (~children, ~requestController) => {
  requestController->RequestController.appendToHead(children)
  H.null
}
