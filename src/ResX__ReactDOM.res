@module("./vendor/hyperons.js")
external jsx: (string, H__domProps.domProps) => Jsx.element = "h"

@module("./vendor/hyperons.js")
external jsxs: (string, H__domProps.domProps) => Jsx.element = "h"

external someElement: Jsx.element => option<Jsx.element> = "%identity"

type domProps = H__domProps.domProps
