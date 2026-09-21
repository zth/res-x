@@jsxConfig({module_: "Hjsx"})

open Test

describe("rendering HTML via JSX", () => {
  test("HTML is escaped", () => {
    let dangerousHtml = `<script>alert("hello!")</script>`
    let jsx = <div> {Hjsx.string(dangerousHtml)} </div>
    expect(jsx->H.renderSyncToString)->Expect.toBe(`<div>${Bun.escapeHTML(dangerousHtml)}</div>`)
  })
})

test("numeric zero is preserved by the compiled JSX factory", () => {
  let jsx = <div> {Hjsx.int(0)} </div>
  expect(jsx->H.renderSyncToString)->Expect.toBe("<div>0</div>")
})
