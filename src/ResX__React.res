type element = Jsx.element

@module("./vendor/hyperons.js")
external jsxs: (string, H__domProps.domProps) => Jsx.element = "h"
type component<'props> = Jsx.component<'props>
type componentLike<'props, 'return> = Jsx.componentLike<'props, 'return>

type fragmentProps = {children?: element}

@module("./vendor/hyperons.js") external jsxFragment: component<fragmentProps> = "Fragment"

@module("./vendor/hyperons.js")
external jsx: (component<'props>, 'props) => Jsx.element = "h"

@val external null: Jsx.element = "null"

external float: float => Jsx.element = "%identity"
external int: int => Jsx.element = "%identity"
external string: string => Jsx.element = "%identity"
external array: array<Jsx.element> => Jsx.element = "%identity"
