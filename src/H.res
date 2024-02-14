@module("./vendor/hyperons.js")
external renderToString: Jsx.element => promise<string> = "render"

/** Renders a subtree to content. Throws if the subtree is asynchronous. */
@module("./vendor/hyperons.js")
@raises(Js.Exn.t)
external renderSyncToString: Jsx.element => string = "renderSync"

@module("./vendor/hyperons.js")
external renderToStream: (Jsx.element, ~onChunk: string => unit=?) => promise<unit> = "render"

module Context = {
  type t<'context>

  type props<'context> = {
    value: 'context,
    children: Jsx.element,
  }

  @module("./vendor/hyperons.js")
  external createContext: 'context => t<'context> = "createContext"

  @module("./vendor/hyperons.js")
  external useContext: t<'context> => 'context = "useContext"

  @get external provider: t<'context> => Jsx.component<props<'context>> = "Provider"
}
