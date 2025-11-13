@@jsxConfig({module_: "Hjsx"})

open Test

describe("style prop handling", () => {
  test("emits the expected style string", () => {
    expect(
      <div style={color: "red"} />->H.renderSyncToString,
    )->Expect.toBe(`<div style="color:red;"></div>`)
  })
})
