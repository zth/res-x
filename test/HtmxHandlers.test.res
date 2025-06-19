open Test
open TestUtils

describe("HTMX handlers", () => {
  testAsync("prefixing of HTMX handler routes work", async () => {
    let _getHandler = Handler.handler->Handlers.hxGet(
      "/test",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(
      _ => {
        Hjsx.null
      },
      ~url="/_api/test",
    )

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Test!`)
  })

  testAsync("security policy can block content", async () => {
    let _getHandler = Handler.handler->Handlers.hxGet(
      "/test-block",
      ~securityPolicy=async _ => SecurityPolicy.Block({
        code: Some(403),
        message: Some("Forbidden"),
      }),
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(
      _ => {
        Hjsx.null
      },
      ~url="/_api/test-block",
    )

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Forbidden`)
    expect(response->Response.status)->Expect.toBe(403)
  })
})
