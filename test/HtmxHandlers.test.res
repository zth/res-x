open Test
open TestUtils

describe("HTMX handlers", () => {
  testAsync("prefixing of HTMX handler routes work", async () => {
    let _getHandler = Handler.testHandler.hxGet(
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
    let _getHandler = Handler.testHandler.hxGet(
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

  testAsync("security policy metadata is forwarded to handler", async () => {
    let _getHandler = Handler.testHandler.hxGet(
      "/test-meta",
      ~securityPolicy=async _ => SecurityPolicy.Allow("meta"),
      ~handler=async ({securityPolicyData}) => {
        Hjsx.string(securityPolicyData)
      },
    )
    let response = await getResponse(~url="/_api/test-meta")

    let text = await response->Response.text

    expect(text)->Expect.toBe(`<!DOCTYPE html>meta`)
  })

  testAsync("delaying GET handler implementation works", async () => {
    let getHandler = Handler.testHandler.hxGetRef("/test-delay")
    Handler.testHandler.hxGetDefine(
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
    let postHandler = Handler.testHandler.hxPostRef("/test-delay")
    Handler.testHandler.hxPostDefine(
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
    let putHandler = Handler.testHandler.hxPutRef("/test-delay")
    Handler.testHandler.hxPutDefine(
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
    let deleteHandler = Handler.testHandler.hxDeleteRef("/test-delay")
    Handler.testHandler.hxDeleteDefine(
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
    let patchHandler = Handler.testHandler.hxPatchRef("/test-delay")
    Handler.testHandler.hxPatchDefine(
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

  testAsync("endpoint URL helpers return the correct URLs", async () => {
    let getHandler = Handler.testHandler.hxGet(
      "/test-url-get",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let postHandler = Handler.testHandler.hxPost(
      "/test-url-post",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let putHandler = Handler.testHandler.hxPut(
      "/test-url-put",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let deleteHandler = Handler.testHandler.hxDelete(
      "/test-url-delete",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let patchHandler = Handler.testHandler.hxPatch(
      "/test-url-patch",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Hjsx.string("Test!")
      },
    )
    let formActionHandler = Handler.testHandler.formAction(
      "/test-form",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.makeRedirect("/test")
      },
    )

    expect(getHandler->Handlers.hxGetToEndpointURL)->Expect.toBe("/_api/test-url-get")
    expect(postHandler->Handlers.hxPostToEndpointURL)->Expect.toBe("/_api/test-url-post")
    expect(putHandler->Handlers.hxPutToEndpointURL)->Expect.toBe("/_api/test-url-put")
    expect(deleteHandler->Handlers.hxDeleteToEndpointURL)->Expect.toBe("/_api/test-url-delete")
    expect(patchHandler->Handlers.hxPatchToEndpointURL)->Expect.toBe("/_api/test-url-patch")
    expect(formActionHandler->Handlers.FormAction.toEndpointURL)->Expect.toBe("/_form/test-form")
  })
})
