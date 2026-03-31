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

  testAsync("formAction takes precedence over endpoint GET and POST routes on the same path", async () => {
    let handler = makeCollisionHandler()

    let _getHandler = handler.endpointGet(
      "/collision-form-after-endpoint",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("ENDPOINT GET")
      },
    )
    let _postHandler = handler.endpointPost(
      "/collision-form-after-endpoint",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("ENDPOINT POST")
      },
    )
    let _formAction = handler.formAction(
      "/collision-form-after-endpoint",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("FORM")
      },
    )

    let getResponse = await getResponseForHandler(
      ~handler,
      ~url="/_shared/collision-form-after-endpoint",
    )
    let postResponse = await getResponseForHandler(
      ~handler,
      ~method=POST,
      ~url="/_shared/collision-form-after-endpoint",
    )

    let getText = await getResponse->Response.text
    let postText = await postResponse->Response.text

    expect(getText)->Expect.toBe("FORM")
    expect(postText)->Expect.toBe("FORM")
  })

  testAsync("existing formAction route takes precedence when endpoint routes are added later", async () => {
    let handler = makeCollisionHandler()

    let _formAction = handler.formAction(
      "/collision-endpoint-after-form",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("FORM")
      },
    )
    let _getHandler = handler.endpointGet(
      "/collision-endpoint-after-form",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("ENDPOINT GET")
      },
    )
    let _postHandler = handler.endpointPost(
      "/collision-endpoint-after-form",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("ENDPOINT POST")
      },
    )

    let getResponse = await getResponseForHandler(
      ~handler,
      ~url="/_shared/collision-endpoint-after-form",
    )
    let postResponse = await getResponseForHandler(
      ~handler,
      ~method=POST,
      ~url="/_shared/collision-endpoint-after-form",
    )

    let getText = await getResponse->Response.text
    let postText = await postResponse->Response.text

    expect(getText)->Expect.toBe("FORM")
    expect(postText)->Expect.toBe("FORM")
  })

  testAsync("existing HTMX route keeps the API path when an endpoint is added later", async () => {
    let handler = makeCollisionHandler()

    let _htmxHandler = handler.hxGet(
      "/collision-api-kind-first",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("HTMX")
      },
    )
    let _endpointHandler = handler.endpointGet(
      "/collision-api-kind-first",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("ENDPOINT")
      },
    )

    let response = await getResponseForHandler(~handler, ~url="/_shared/collision-api-kind-first")
    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>HTMX`)
  })

  testAsync("existing endpoint route keeps the API path when HTMX is added later", async () => {
    let handler = makeCollisionHandler()

    let _endpointHandler = handler.endpointGet(
      "/collision-api-kind-second",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("ENDPOINT")
      },
    )
    let _htmxHandler = handler.hxGet(
      "/collision-api-kind-second",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("HTMX")
      },
    )

    let response = await getResponseForHandler(~handler, ~url="/_shared/collision-api-kind-second")
    let text = await response->Response.text

    expect(text)->Expect.toBe("ENDPOINT")
  })
})
