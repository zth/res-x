@jsx.component
let make = (~children) => {
  <head> {children} </head>
}

module RenderInHead = {
  @jsx.component
  let make = (~handler: ResX.Handlers.t<_>, ~children) => {
    let ctx = handler.useContext()
    ctx.requestController.appendToHead(children)

    Hjsx.null
  }
}
