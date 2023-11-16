type myVariant = One | Two

let myVariantFromString = (a: FormData.formDataValueResult) => {
  switch a {
  | String("one") => Ok(One)
  | String("two") => Ok(Two)
  | other => Error(`Unknown value: "${String.make(other)}"`)
  }
}
let onButtonBlick = HtmxHandler.handler->ResX.Handlers.hxPost("/button-click", ~handler=async ({
  request,
}) => {
  try {
    let formData = await request->Request.formData
    let firstName = formData->ResX.FormDataHelpers.expectString("firstName")
    let lastName = formData->ResX.FormDataHelpers.expectString("lastName")
    let _myvariant =
      formData->ResX.FormDataHelpers.expectCustom("myVariant", ~decoder=myVariantFromString)

    <span> {H.string("Hi " ++ firstName ++ " " ++ lastName ++ "!")} </span>
  } catch {
  | Exn.Error(_) => <ErrorMessage message="Something went wrong..." />
  }
})

@react.component
let make = (~name) => {
  <form action="post">
    <button hxSwap={ResX.Htmx.Swap.make(InnerHTML, ~modifier=Transition)} hxPost={onButtonBlick}>
      {H.string("Hello " ++ name)}
    </button>
    <input type_="text" name="firstName" value="" />
    <input type_="text" name="lastName" value="" />
  </form>
}
