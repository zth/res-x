type element = Jsx.element

type component<'props> = Jsx.component<'props>
type componentLike<'props, 'return> = Jsx.componentLike<'props, 'return>

type fragmentProps = {children?: element}

@module("./vendor/hyperons.js") external jsxFragment: component<fragmentProps> = "Fragment"

@module("./vendor/hyperons.js")
external jsx: (component<'props>, 'props) => Jsx.element = "h"

@module("./vendor/hyperons.js")
external jsxs: (component<'props>, 'props) => element = "h"

@val external null: Jsx.element = "null"

external float: float => Jsx.element = "%identity"
external int: int => Jsx.element = "%identity"
external string: string => Jsx.element = "%identity"
external array: array<Jsx.element> => Jsx.element = "%identity"

module Elements = {
  @module("./vendor/hyperons.js")
  external jsx: (string, H__domProps.domProps) => Jsx.element = "h"

  @module("./vendor/hyperons.js")
  external jsxs: (string, H__domProps.domProps) => Jsx.element = "h"

  external someElement: Jsx.element => option<Jsx.element> = "%identity"

  type domProps = H__domProps.domProps
}
