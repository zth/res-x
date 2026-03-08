open Test
open TestUtils

let makeCollisionHandler = () =>
  Handlers.make(
    ~requestToContext=async (_): Handler.context => {shouldAppendToHead: false},
    ~options={
      htmxApiPrefix: "/_shared",
      formActionHandlerApiPrefix: "/_shared",
    },
  )

describe("route collisions", () => {
  testAsync("formAction takes precedence over HTMX GET and POST routes on the same path", async () => {
    let handler = makeCollisionHandler()

    let _getHandler = handler.hxGet(
      "/collision-form-after-htmx",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("HTMX GET")
      },
    )
    let _postHandler = handler.hxPost(
      "/collision-form-after-htmx",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("HTMX POST")
      },
    )
    let _formAction = handler.formAction(
      "/collision-form-after-htmx",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("FORM")
      },
    )

    let getResponse = await getResponseForHandler(
      ~handler,
      ~url="/_shared/collision-form-after-htmx",
    )
    let postResponse = await getResponseForHandler(
      ~handler,
      ~method=POST,
      ~url="/_shared/collision-form-after-htmx",
    )

    let getText = await getResponse->Response.text
    let postText = await postResponse->Response.text

    expect(getText)->Expect.toBe("FORM")
    expect(postText)->Expect.toBe("FORM")
  })

  testAsync("existing formAction route takes precedence when HTMX routes are added later", async () => {
    let handler = makeCollisionHandler()

    let _formAction = handler.formAction(
      "/collision-htmx-after-form",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("FORM")
      },
    )
    let _getHandler = handler.hxGet(
      "/collision-htmx-after-form",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("HTMX GET")
      },
    )
    let _postHandler = handler.hxPost(
      "/collision-htmx-after-form",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("HTMX POST")
      },
    )

    let getResponse = await getResponseForHandler(
      ~handler,
      ~url="/_shared/collision-htmx-after-form",
    )
    let postResponse = await getResponseForHandler(
      ~handler,
      ~method=POST,
      ~url="/_shared/collision-htmx-after-form",
    )

    let getText = await getResponse->Response.text
    let postText = await postResponse->Response.text

    expect(getText)->Expect.toBe("FORM")
    expect(postText)->Expect.toBe("FORM")
  })
})
