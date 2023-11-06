type myVariant = One | Two

let myVariantFromString = a => {
  switch a {
  | FormData.String("one") => Ok(One)
  | String("two") => Ok(Two)
  | other => Error(`Unknown value: "${String.make(other)}"`)
  }
}
let onButtonBlick = HtmxHandler.handler->ResX.Handlers.post("/button-click", ~handler=async ({
  request,
}) => {
  try {
    let formData = await request->Bun.Request.formData
    let firstName = formData->FormData.expectString("firstName")
    let lastName = formData->FormData.expectString("lastName")
    let _myvariant = formData->FormData.expectCustom("myVariant", ~decoder=myVariantFromString)

    <span> {H.string("Hi " ++ firstName ++ " " ++ lastName ++ "!")} </span>
  } catch {
  | Exn.Error(_) => <ErrorMessage message="Something went wrong..." />
  }
})

@react.component
let make = (~name) => {
  <form action="post">
    <button hxSwap={Htmx.Swap.make(InnerHTML, ~modifier=Transition)} hxPost={onButtonBlick}>
      {H.string("Hello " ++ name)}
    </button>
    <input type_="text" name="firstName" value="" />
    <input type_="text" name="lastName" value="" />
  </form>
}
