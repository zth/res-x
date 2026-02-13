open Test
open TestUtils

describe("CSRF", () => {
  testAsync("Token component renders hidden input with token", async () => {
    let text = await getContentInBody(
      _ => {
        <Html>
          <form>
            <CSRFToken />
          </form>
        </Html>
      },
    )

    let token =
      /name="resx_csrf_token" type="hidden" value="(.+)"/
      ->RegExp.exec(text)
      ->Option.getOrThrow
      ->Array.getUnsafe(1)
      ->Option.getOr("")

    expect(text)->Expect.toBe(
      `<!DOCTYPE html><html><head></head><body><form><input name="resx_csrf_token" type="hidden" value="${token}"/></form></body></html>`,
    )
  })
  testAsync("hxPost blocks without token when csrfCheck is true", async () => {
    let _handler =
      Handler.testHandler->Handlers.hxPost(
        "/csrf-hx-post",
        ~securityPolicy=SecurityPolicy.allow,
        ~csrfCheck=true,
        ~handler=async _ => Hjsx.string("ok"),
      )

    let response = await getResponseWithInit(~url="/_api/csrf-hx-post", ~init={method: "POST"})
    let text = await response->Response.text
    expect(response->Response.status)->Expect.toBe(403)
    expect(text)->Expect.toBe(`<!DOCTYPE html>Invalid CSRF token.`)
  })

  testAsync("hxPost passes with valid token when csrfCheck is true", async () => {
    let _handler =
      Handler.testHandler->Handlers.hxPost(
        "/csrf-hx-post-valid",
        ~securityPolicy=SecurityPolicy.allow,
        ~csrfCheck=true,
        ~handler=async _ => Hjsx.string("ok"),
      )

    let token = Bun.CSRF.generate()
    let headers: HeadersInit.t = HeadersInit.FromArray([("X-CSRF-Token", token)])
    let response = await getResponseWithInit(
      ~url="/_api/csrf-hx-post-valid",
      ~init={method: "POST", headers},
    )
    let text = await response->Response.text
    expect(response->Response.status)->Expect.toBe(200)
    expect(text)->Expect.toBe(`<!DOCTYPE html>ok`)
  })

  testAsync("hxPost passes with token from CSRFToken form field", async () => {
    let _handler =
      Handler.testHandler->Handlers.hxPost(
        "/csrf-hx-post-component-token",
        ~securityPolicy=SecurityPolicy.allow,
        ~csrfCheck=true,
        ~handler=async ({request}) => {
          let fd = await request->Request.formData
          switch fd->FormData.get("name") {
          | String(v) => Hjsx.string(v)
          | _ => Hjsx.string("name-missing")
          }
        },
      )

    let html = await getContentInBody(
      _ => {
        <Html>
          <form>
            <CSRFToken />
          </form>
        </Html>
      },
    )

    let token =
      /name="resx_csrf_token" type="hidden" value="(.+)"/
      ->RegExp.exec(html)
      ->Option.getOrThrow
      ->Array.getUnsafe(1)
      ->Option.getOr("")

    let formBody = URLSearchParams.make()
    formBody->URLSearchParams.append("resx_csrf_token", token)
    formBody->URLSearchParams.append("name", "Ada")

    let response = await getResponseWithInit(
      ~url="/_api/csrf-hx-post-component-token",
      ~init={
        method: "POST",
        body: Null.fromOption(Some(BodyInit.makeFromURLSearchParams(formBody))),
      },
    )

    let text = await response->Response.text
    expect(response->Response.status)->Expect.toBe(200)
    expect(text)->Expect.toBe(`<!DOCTYPE html>Ada`)
  })

  testAsync("formAction blocks without token when csrfCheck is true", async () => {
    let _fa =
      Handler.testHandler->Handlers.formAction(
        "/csrf-form",
        ~securityPolicy=SecurityPolicy.allow,
        ~csrfCheck=true,
        ~handler=async _ => Response.make("ok"),
      )

    let headers: HeadersInit.t = HeadersInit.FromArray([
      ("Content-Type", "application/x-www-form-urlencoded"),
    ])
    let response = await getResponseWithInit(
      ~url="/_form/csrf-form",
      ~init={method: "POST", headers},
    )
    let text = await response->Response.text
    expect(response->Response.status)->Expect.toBe(403)
    expect(text)->Expect.toBe("Invalid CSRF token.")
  })

  testAsync("formAction passes with valid token when csrfCheck is true", async () => {
    let _fa =
      Handler.testHandler->Handlers.formAction(
        "/csrf-form-valid",
        ~securityPolicy=SecurityPolicy.allow,
        ~csrfCheck=true,
        ~handler=async _ => Response.make("ok"),
      )

    let token = Bun.CSRF.generate()
    let headers: HeadersInit.t = HeadersInit.FromArray([("X-CSRF-Token", token)])
    let response = await getResponseWithInit(
      ~url="/_form/csrf-form-valid",
      ~init={method: "POST", headers},
    )
    let text = await response->Response.text
    expect(response->Response.status)->Expect.toBe(200)
    expect(text)->Expect.toBe("ok")
  })

  testAsync("formAction passes with token from CSRFToken form field", async () => {
    let _fa =
      Handler.testHandler->Handlers.formAction(
        "/csrf-form-component-token",
        ~securityPolicy=SecurityPolicy.allow,
        ~csrfCheck=true,
        ~handler=async ({request}) => {
          let fd = await request->Request.formData
          switch fd->FormData.get("name") {
          | String(v) => Response.make(v)
          | _ => Response.make("name-missing", ~options={status: 400})
          }
        },
      )

    let html = await getContentInBody(
      _ => {
        <Html>
          <form>
            <CSRFToken />
          </form>
        </Html>
      },
    )

    let token =
      /name="resx_csrf_token" type="hidden" value="(.+)"/
      ->RegExp.exec(html)
      ->Option.getOrThrow
      ->Array.getUnsafe(1)
      ->Option.getOr("")

    let formBody = URLSearchParams.make()
    formBody->URLSearchParams.append("resx_csrf_token", token)
    formBody->URLSearchParams.append("name", "Ada")

    let response = await getResponseWithInit(
      ~url="/_form/csrf-form-component-token",
      ~init={
        method: "POST",
        body: Null.fromOption(Some(BodyInit.makeFromURLSearchParams(formBody))),
      },
    )
    let text = await response->Response.text
    expect(response->Response.status)->Expect.toBe(200)
    expect(text)->Expect.toBe("Ada")
  })

  testAsync("defaultCsrfCheck enforces CSRF when enabled on handler make", async () => {
    let customHandler = Handlers.make(
      ~requestToContext=async (_): Handler.context => {shouldAppendToHead: false},
      ~options={defaultCsrfCheck: ForAllMethods(true)},
    )

    let _hx =
      customHandler->Handlers.hxPost(
        "/csrf-default",
        ~securityPolicy=SecurityPolicy.allow,
        ~handler=async _ => Hjsx.string("ok"),
      )

    // Start server manually for this custom handler
    let (port, unsubPort) = getPort()
    let server = Bun.serve({
      port,
      development: true,
      fetch: async (request, _server) =>
        await Handlers.handleRequest(
          customHandler,
          {
            request,
            render: async _ => Hjsx.null,
            setupHeaders: () => Headers.make(~init=FromArray([("Content-Type", "text/html")])),
          },
        ),
    })

    // Missing token should 403
    let res1 = await fetch(
      `http://localhost:${port->Int.toString}/_api/csrf-default`,
      ~init={method: "POST"},
    )
    expect(res1->Response.status)->Expect.toBe(403)

    // With token should 200
    let token = Bun.CSRF.generate()
    let headers: HeadersInit.t = HeadersInit.FromArray([("X-CSRF-Token", token)])
    let res2 = await fetch(
      `http://localhost:${port->Int.toString}/_api/csrf-default`,
      ~init={method: "POST", headers},
    )
    let text2 = await res2->Response.text
    expect(res2->Response.status)->Expect.toBe(200)
    expect(text2)->Expect.toBe(`<!DOCTYPE html>ok`)

    server->Bun.Server.stop(~closeActiveConnections=true)
    unsubPort()
  })

  testAsync("per-method default: POST enforced, GET relaxed", async () => {
    let customHandler = Handlers.make(
      ~requestToContext=async (_): Handler.context => {shouldAppendToHead: false},
      ~options={
        defaultCsrfCheck: PerMethod({
          get: Some(false),
          post: Some(true),
          put: None,
          patch: None,
          delete: None,
        }),
      },
    )

    let _hxGet =
      customHandler->Handlers.hxGet(
        "/pm",
        ~securityPolicy=SecurityPolicy.allow,
        ~handler=async _ => Hjsx.string("ok"),
      )
    let _hxPost =
      customHandler->Handlers.hxPost(
        "/pm",
        ~securityPolicy=SecurityPolicy.allow,
        ~handler=async _ => Hjsx.string("ok"),
      )

    let (port, unsubPort) = getPort()
    let server = Bun.serve({
      port,
      development: true,
      fetch: async (request, _server) =>
        await Handlers.handleRequest(
          customHandler,
          {
            request,
            render: async _ => Hjsx.null,
            setupHeaders: () => Headers.make(~init=FromArray([("Content-Type", "text/html")])),
          },
        ),
    })

    // GET should be allowed without token
    let resGet = await fetch(`http://localhost:${port->Int.toString}/_api/pm`)
    let textGet = await resGet->Response.text
    expect(resGet->Response.status)->Expect.toBe(200)
    expect(textGet)->Expect.toBe(`<!DOCTYPE html>ok`)

    // POST should be 403 without token
    let resPostNo = await fetch(
      `http://localhost:${port->Int.toString}/_api/pm`,
      ~init={method: "POST"},
    )
    expect(resPostNo->Response.status)->Expect.toBe(403)

    // POST should be 200 with token
    let token = Bun.CSRF.generate()
    let headers: HeadersInit.t = HeadersInit.FromArray([("X-CSRF-Token", token)])
    let resPostYes = await fetch(
      `http://localhost:${port->Int.toString}/_api/pm`,
      ~init={method: "POST", headers},
    )
    let textPostYes = await resPostYes->Response.text
    expect(resPostYes->Response.status)->Expect.toBe(200)
    expect(textPostYes)->Expect.toBe(`<!DOCTYPE html>ok`)

    server->Bun.Server.stop(~closeActiveConnections=true)
    unsubPort()
  })
})
