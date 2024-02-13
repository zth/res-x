@jsx.component
let make = (~children) => {
  <head> {children} </head>
}

module RenderInHead = {
  @jsx.component
  let make = (~handler, ~children) => {
    let ctx = handler->ResX.Handlers.useContext
    ctx.requestController->ResX.RequestController.appendToHead(children)

    Hjsx.null
  }
}
