open Test
open TestUtils

describe("rendering", () => {
  testAsync("render in head", async () => {
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
            H.null
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
})
