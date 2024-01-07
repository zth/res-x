open Test
open TestUtils

describe("HTMX handlers", () => {
  testAsync("prefixing of HTMX handler routes work", async () => {
    let _getHandler = Handler.handler->Handlers.hxGet(
      "/test",
      ~handler=async _ => {
        H.string("Test!")
      },
    )
    let response = await getResponse(
      _ => {
        H.null
      },
      ~url="/_api/test",
    )

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Test!`)
  })
})
