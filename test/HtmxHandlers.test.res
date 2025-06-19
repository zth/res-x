open Test
open TestUtils

describe("HTMX handlers", () => {
  testAsync("prefixing of HTMX handler routes work", async () => {
    let _getHandler = Handler.testHandler->Handlers.hxGet(
      "/test",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(~url="/_api/test")

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Test!`)
  })

  testAsync("security policy can block content", async () => {
    let _getHandler = Handler.testHandler->Handlers.hxGet(
      "/test-block",
      ~securityPolicy=async _ => SecurityPolicy.Block({
        code: Some(403),
        message: Some("Forbidden"),
      }),
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(~url="/_api/test-block")

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Forbidden`)
    expect(response->Response.status)->Expect.toBe(403)
  })

  testAsync("delaying GET handler implementation works", async () => {
    let getHandler = Handler.testHandler->Handlers.hxGetRef("/test-delay")
    Handler.testHandler->Handlers.hxGetDefine(
      getHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(~url="/_api/test-delay")

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Test!`)
  })

  testAsync("delaying POST handler implementation works", async () => {
    let postHandler = Handler.testHandler->Handlers.hxPostRef("/test-delay")
    Handler.testHandler->Handlers.hxPostDefine(
      postHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(~method=POST, ~url="/_api/test-delay")

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Test!`)
  })

  testAsync("delaying PUT handler implementation works", async () => {
    let putHandler = Handler.testHandler->Handlers.hxPutRef("/test-delay")
    Handler.testHandler->Handlers.hxPutDefine(
      putHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(~method=PUT, ~url="/_api/test-delay")

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Test!`)
  })

  testAsync("delaying DELETE handler implementation works", async () => {
    let deleteHandler = Handler.testHandler->Handlers.hxDeleteRef("/test-delay")
    Handler.testHandler->Handlers.hxDeleteDefine(
      deleteHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(~method=DELETE, ~url="/_api/test-delay")

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Test!`)
  })

  testAsync("delaying PATCH handler implementation works", async () => {
    let patchHandler = Handler.testHandler->Handlers.hxPatchRef("/test-delay")
    Handler.testHandler->Handlers.hxPatchDefine(
      patchHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let response = await getResponse(~method=PATCH, ~url="/_api/test-delay")

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>Test!`)
  })
})
