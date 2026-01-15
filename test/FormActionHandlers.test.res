open Test
open TestUtils

describe("Form action handlers", () => {
  testAsync("prefixing of form action handler routes work", async () => {
    let _getHandler = Handler.testHandler->Handlers.formAction(
      "/test",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Test!")
      },
    )
    let response = await getResponse(
      ~getContent=_ => {
        Hjsx.string("nope")
      },
      ~url="/_form/test",
    )

    let text = await response->Response.text

    expect(text)->Expect.toBe(`Test!`)
  })

  testAsync("security policy metadata is forwarded to handler", async () => {
    let _getHandler = Handler.testHandler->Handlers.formAction(
      "/test-meta",
      ~securityPolicy=async _ => SecurityPolicy.Allow(42),
      ~handler=async ({securityPolicyData}) => {
        Response.make(securityPolicyData->Int.toString)
      },
    )
    let response = await getResponse(
      ~getContent=_ => {
        Hjsx.string("nope")
      },
      ~url="/_form/test-meta",
    )

    let text = await response->Response.text

    expect(text)->Expect.toBe(`42`)
  })
})
