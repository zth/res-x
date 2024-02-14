@unboxed
type inputValue = | @as("on") On | @as("off") Off

@unboxed
type inputValueDecode = | ...inputValue | Other(string)

let onForm = HtmxHandler.handler->ResX.Handlers.hxPost("/user-single", ~handler=async ({
  request,
}) => {
  let formData = await request->Request.formData
  try {
    let name = formData->ResX.FormDataHelpers.expectString("name")
    let active = formData->ResX.FormDataHelpers.expectCheckbox("active")

    <div>
      {Hjsx.string(
        `Some user ${name} is ${switch active {
          | false => "not active"
          | true => "active"
          }}`,
      )}
    </div>
  } catch {
  | Exn.Error(err) =>
    Console.error(err)
    <div> {Hjsx.string("Failed")} </div>
  }
})

@jsx.component
let make = (~innerContent, ~userId) => {
  let ctx = HtmxHandler.useContext()
  ctx.headers->Headers.set("Content-Type", "text/html")
  <div className="p-8">
    <form
      hxPost={onForm}
      hxSwap={ResX.Htmx.Swap.make(InnerHTML)}
      hxTarget={ResX.Htmx.Target.make(CssSelector("#user-single"))}>
      <img src={ResXAssets.assets.images__test_img_jpeg} />
      <div id="user-single">
        <div className="text-2xl bg-slate-200 text-gray-500">
          {Hjsx.string(`User 123 3333 ${userId}`)}
        </div>
      </div>
      <div className="p-2">
        <input className="p-2" type_="text" name="name" />
      </div>
      <div className="p-2">
        <input
          type_="text"
          name="lastName"
          required=true
          className="invalid:border-green-400 border border-gray-500"
          resXValidityMessage={ResX.Client.ValidityMessage.make({
            valueMissing: "Yo, you need to fill this in!",
          })}
        />
      </div>
      <div className="p-2">
        <input type_="checkbox" name="active" />
      </div>
      <div className="p-2">
        <label>
          <input type_="radio" value="on" name="status" />
          {Hjsx.string("On")}
        </label>
        <label>
          <input type_="radio" value="off" name="status" />
          {Hjsx.string("Off")}
        </label>
      </div>
      <div className="p-2">
        <textarea name="description" />
      </div>
      <div className="p-2">
        <button
          id="test"
          resXOnClick={ResX.Client.Actions.make([
            ToggleClass({className: "text-xl", target: This}),
          ])}>
          {Hjsx.string("Submit form")}
        </button>
      </div>
      <ResX.ErrorBoundary
        renderError={err => {
          <div> {Hjsx.string("Oops, failed! " ++ err->Exn.message->Option.getOr("-"))} </div>
        }}>
        <FailingComponent />
      </ResX.ErrorBoundary>
    </form>
    {innerContent}
  </div>
}
