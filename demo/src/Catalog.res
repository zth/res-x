@jsx.component
let make = () => {
  <main className="max-w-3xl mx-auto p-8">
    <h1 className="text-3xl font-bold"> {Hjsx.string("The reading room")} </h1>
    <p className="my-4"> {Hjsx.string("A few books for your next quiet afternoon.")} </p>
    <section className="grid gap-4">
      {[
        ("The Left Hand of Darkness", "Ursula K. Le Guin"),
        ("Piranesi", "Susanna Clarke"),
        ("Invisible Cities", "Italo Calvino"),
      ]->Array.map(((title, author)) => {
        <article className="border rounded-lg p-5">
          <h2 className="text-xl font-semibold"> {Hjsx.string(title)} </h2>
          <p className="text-gray-600"> {Hjsx.string(author)} </p>
        </article>
      })->Hjsx.array}
    </section>
  </main>
}
