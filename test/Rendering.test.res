@@jsxConfig({module_: "Hjsx"})

open Test
open TestUtils

describe("rendering", () => {
  describe("render in head", () => {
    module AsyncComponent = {
      @jsx.component
      let make = async () => {
        let context = Handler.testHandler->Handlers.useContext

        <RenderInHead requestController=context.requestController>
          <meta name="test" content="test" />
        </RenderInHead>
      }
    }

    testAsync(
      "render in head with async component",
      async () => {
        let text = await getContentInBody(
          _renderConfig => {
            <Html>
              <AsyncComponent />
            </Html>
          },
        )

        expect(
          text,
        )->Expect.toBe(`<!DOCTYPE html><html><head><meta content="test" name="test"/></head><body></body></html>`)
      },
    )

    testAsync(
      "render in head",
      async () => {
        let text = await getContentInBody(
          renderConfig => {
            <Html>
              <RenderInHead requestController=renderConfig.requestController>
                <meta name="test" content="test" />
              </RenderInHead>
            </Html>
          },
        )

        expect(
          text,
        )->Expect.toBe(`<!DOCTYPE html><html><head><meta content="test" name="test"/></head><body></body></html>`)
      },
    )
  })

  describe("DOCTYPE", () => {
    testAsync(
      "change DOCTYPE",
      async () => {
        let text = await getContentInBody(
          renderConfig => {
            renderConfig.requestController->RequestController.setDocHeader(
              Some(`<?xml version="1.0" encoding="UTF-8"?>`),
            )
            Hjsx.null
          },
        )

        expect(text)->Expect.toBe(`<?xml version="1.0" encoding="UTF-8"?>`)
      },
    )

    testAsync(
      "remove DOCTYPE",
      async () => {
        let text = await getContentInBody(
          renderConfig => {
            renderConfig.requestController->RequestController.setDocHeader(None)
            <Html>
              <div />
            </Html>
          },
        )

        expect(text)->Expect.toBe(`<html><head></head><body><div></div></body></html>`)
      },
    )
  })

  describe("Security", () => {
    testAsync(
      "title segments are escaped",
      async () => {
        let text = await getContentInBody(
          renderConfig => {
            renderConfig.requestController->RequestController.appendTitleSegment("</title></head>")
            <Html>
              <div />
            </Html>
          },
        )

        expect(
          text,
        )->Expect.toBe(`<!DOCTYPE html><html><head><title>&lt;/title&gt;&lt;/head&gt;</title></head><body><div></div></body></html>`)
      },
    )
  })

  describe("hooks", () => {
    testAsync(
      "onBeforeSendResponse change status",
      async () => {
        let response = await getResponse(
          ~getContent=_renderConfig => {
            <Html>
              <div> {Hjsx.string("Hi!")} </div>
            </Html>
          },
          ~onBeforeSendResponse=async config => {
            Response.make(
              await config.response->Response.text,
              ~options={
                status: 400,
                headers: FromDict(config.response->Response.headers->Headers.toJSON),
              },
            )
          },
        )

        let status = response->Response.status
        let text = await response->Response.text

        expect(status)->Expect.toBe(400)
        expect(
          text,
        )->Expect.toBe(`<!DOCTYPE html><html><head></head><body><div>Hi!</div></body></html>`)
      },
    )

    testAsync(
      "onBeforeSendResponse set header",
      async () => {
        let response = await getResponse(
          ~getContent=_renderConfig => {
            <Html>
              <div> {Hjsx.string("Hi!")} </div>
            </Html>
          },
          ~onBeforeSendResponse=async config => {
            config.response->Response.headers->Headers.set("x-user-id", "1")
            config.response
          },
        )

        let userIdHeader = response->Response.headers->Headers.get("x-user-id")
        expect(userIdHeader)->Expect.toBe(Some("1"))
      },
    )
  })
})
