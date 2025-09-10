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
    describe(
      "onBeforeBuildResponse can set appended header content",
      () => {
        let getResponseWithShouldAppendToHeadValue = shouldAppendToHead => {
          getResponse(
            ~getContent=({context}) => {
              context.shouldAppendToHead = shouldAppendToHead
              <Html>
                <div> {Hjsx.string("Hi!")} </div>
              </Html>
            },
            ~onBeforeBuildResponse=async config => {
              if config.context.shouldAppendToHead {
                config.requestController->RequestController.appendToHead(
                  <meta name="test" content="test" />,
                )
              }
            },
          )
        }
        testAsync(
          "can read context to control appending to head - should append",
          async () => {
            let response = await getResponseWithShouldAppendToHeadValue(true)
            let text = await response->Response.text
            expect(
              text,
            )->Expect.toBe(`<!DOCTYPE html><html><head><meta content="test" name="test"/></head><body><div>Hi!</div></body></html>`)
          },
        )

        testAsync(
          "can read context to control appending to head - should not append",
          async () => {
            let response = await getResponseWithShouldAppendToHeadValue(false)
            let text = await response->Response.text
            expect(
              text,
            )->Expect.toBe(`<!DOCTYPE html><html><head></head><body><div>Hi!</div></body></html>`)
          },
        )
      },
    )

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

  testAsync("escaped and raw content", async () => {
    let text = await getContentInBody(
      _renderConfig => {
        <div>
          {Hjsx.string("<div>Hi!</div>")}
          {Hjsx.dangerouslyOutputUnescapedContent("<span>Hi!</span>")}
        </div>
      },
    )

    expect(
      text,
    )->Expect.toBe(`<!DOCTYPE html><div>&lt;div&gt;Hi!&lt;/div&gt;<span>Hi!</span></div>`)
  })

  describe("CSV export", () => {
    testAsync(
      "CSV with content that would be HTML escaped",
      async () => {
        let response = await getResponse(
          ~getContent=renderConfig => {
            renderConfig.requestController->RequestController.setDocHeader(None)

            renderConfig.headers->Headers.set("Content-Type", "text/csv; charset=UTF-8")
            renderConfig.headers->Headers.set(
              "Content-Disposition",
              "attachment; filename=\"test.csv\"",
            )

            // CSV content with characters that would be HTML escaped: <, >, &, quotes
            let csvContent = `Name,Description,Tags
"John & Jane Doe","<Special> characters & symbols","tag1,tag2"
"Bob's Company","Uses "quotes" & <brackets>","web,tech"
"Test Corp","R&D Department","research&development"`

            Hjsx.dangerouslyOutputUnescapedContent(csvContent)
          },
        )

        let contentType = response->Response.headers->Headers.get("Content-Type")
        let contentDisposition = response->Response.headers->Headers.get("Content-Disposition")
        let text = await response->Response.text

        expect(contentType)->Expect.toBe(Some("text/csv; charset=UTF-8"))
        expect(contentDisposition)->Expect.toBe(Some("attachment; filename=\"test.csv\""))

        // Verify CSV content is not HTML escaped (no &lt;, &gt;, &amp;, etc.)
        expect(text)->Expect.toBe(`Name,Description,Tags
"John & Jane Doe","<Special> characters & symbols","tag1,tag2"
"Bob's Company","Uses "quotes" & <brackets>","web,tech"
"Test Corp","R&D Department","research&development"`)
      },
    )

    testAsync(
      "demonstrates difference with HTML escaping",
      async () => {
        let text = await getContentInBody(
          _renderConfig => {
            let csvContent = `"Company","Description"
"Bob's Corp","<Special> characters & symbols"`

            // This would incorrectly escape the CSV content for HTML
            <div> {Hjsx.string(csvContent)} </div>
          },
        )

        // Show that using Hjsx.string would escape the content, making it invalid CSV
        expect(text)->Expect.toBe(`<!DOCTYPE html><div>&quot;Company&quot;,&quot;Description&quot;
&quot;Bob&#x27;s Corp&quot;,&quot;&lt;Special&gt; characters &amp; symbols&quot;</div>`)
      },
    )
  })
})
