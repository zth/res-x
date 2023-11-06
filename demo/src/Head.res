@react.component
let make = (~children) => {
  <head> {children} </head>
}

module RenderInHead = {
  @react.component
  let make = (~handler, ~children) => {
    let ctx = handler->ResX.Handlers.useContext
    ctx.requestController->ResX__RequestController.appendToHead(children)

    H.null
  }
}
