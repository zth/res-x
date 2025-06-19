open Test
open TestUtils

describe("Form action handlers", () => {
  testAsync("prefixing of form action handler routes work", async () => {
    let _getHandler = Handler.handler->Handlers.formAction(
      "/test",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Test!")
      },
    )
    let response = await getResponse(
      _ => {
        Hjsx.string("nope")
      },
      ~url="/_form/test",
    )

    let text = await response->Response.text

    expect(text)->Expect.toBe(`Test!`)
  })
})
