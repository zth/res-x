@@jsxConfig({module_: "Hjsx"})

open Test

describe("data prop rendering", () => {
  test("regular data attribute still behaves as a string attribute", () => {
    let html = <object data="/preview.svg" />->H.renderSyncToString
    expect(html)->Expect.toBe(`<object data="/preview.svg"></object>`)
  })

  test("__rawProps emits arbitrary attributes", () => {
    let html = <div __rawProps={dict{
      "hx-get": JSON.String("/search"),
      "aria-description": JSON.String("From raw props"),
      "x-flag": JSON.Boolean(true),
    }} />->H.renderSyncToString

    expect(
      html,
    )->Expect.toBe(`<div hx-get="/search" aria-description="From raw props" x-flag="true"></div>`)
  })

  test("__rawProps can override already bound JSX props by emitting duplicates later", () => {
    let html = <div
      id="from-typed"
      className="from-typed"
      dataTestId="from-typed"
      __rawProps={dict{
        "id": JSON.String("from-raw"),
        "class": JSON.String("from-raw"),
        "data-testid": JSON.String("from-raw"),
      }}
    />->H.renderSyncToString

    expect(
      html,
    )->Expect.toBe(`<div class="from-typed" data-testid="from-typed" id="from-typed" id="from-raw" class="from-raw" data-testid="from-raw"></div>`)
  })

  test("__rawProps skips invalid names and can not inject attributes", () => {
    let html = <div __rawProps={dict{
      "bad name": JSON.String("x"),
      "\"onclick": JSON.String("alert(1)"),
      "safe-name": JSON.String(`\" autofocus=\"true\"`),
    }} />->H.renderSyncToString

    expect(html)->Expect.toBe(`<div safe-name="&quot; autofocus=&quot;true&quot;"></div>`)
  })

  test("__rawProps can emit duplicate typed data attribute", () => {
    let html = <object
      data="/from-typed.svg"
      __rawProps={dict{
        "data": JSON.String("/from-raw.svg"),
      }}
    />->H.renderSyncToString

    expect(html)->Expect.toBe(`<object data="/from-typed.svg" data="/from-raw.svg"></object>`)
  })
})
