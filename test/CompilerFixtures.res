@@jsxConfig({module_: "Hjsx"})

let card = (title, author) => {
  <article className="book">
    <h2> {Hjsx.string(title)} </h2>
    <p> {Hjsx.string(author)} </p>
    <footer> {Hjsx.string("Read & enjoy")} </footer>
  </article>
}

let catalog = count => {
  <main id="catalog">
    <h1> {Hjsx.string("Reading room")} </h1>
    {Array.fromInitializer(~length=count, i => card(`Book ${i->Int.toString}`, "A <writer>"))->Hjsx.array}
  </main>
}

let staticText = () => <div title="<&\"'"> {Hjsx.string("<&>\"' 🦊")} </div>

let captureOrder = visit => {
  <div>
    <span> {Hjsx.string(visit("first"))} </span>
    <span> {Hjsx.string(visit("second"))} </span>
  </div>
}

let fallback = (css, value) => {
  <section className=css>
    <span> {Hjsx.string(value)} </span>
    <input disabled=true />
  </section>
}

let context = H.Context.createContext("default")
module Provider = {
  let make = context->H.Context.provider
}
module Consumer = {
  @jsx.component
  let make = () => <b> {Hjsx.string(context->H.Context.useContext)} </b>
}
let contextual = value => <Provider value> <div> <Consumer /> </div> </Provider>

module AsyncChild = {
  @jsx.component
  let make = async (~value) => {
    await Promise.resolve()
    <em> {Hjsx.string(value)} </em>
  }
}
let asynchronous = value => <div> <AsyncChild value /> <span> {Hjsx.string("after")} </span> </div>

let literal = () => <div title="A & B's" className=""> {Hjsx.string("<safe> & sound")} </div>
