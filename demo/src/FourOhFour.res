@react.component
let make = (~setGenericTitle=false) => {
  let context = HtmxHandler.useContext()
  context.requestController->ResX.RequestController.setStatus(404)

  if setGenericTitle {
    context.requestController->ResX.RequestController.setFullTitle("Not Found")
  }

  <div> {H.string("404")} </div>
}
