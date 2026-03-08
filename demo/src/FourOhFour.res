@jsx.component
let make = (~setGenericTitle=false) => {
  let context = HtmxHandler.useContext()
  context.requestController.setStatus(404)

  if setGenericTitle {
    context.requestController.setFullTitle("Not Found")
  }

  <div> {Hjsx.string("404")} </div>
}
