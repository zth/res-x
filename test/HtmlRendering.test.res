module React = ResX__React
module ReactDOM = ResX__ReactDOM

open Test

describe("rendering HTML via JSX", () => {
  test("HTML is escaped", () => {
    let dangerousHtml = `<script>alert("hello!")</script>`
    let jsx = <div> {H.string(dangerousHtml)} </div>
    expect(jsx->H.renderSyncToString)->Expect.toBe(`<div>${Bun.escapeHTML(dangerousHtml)}</div>`)
  })
})
