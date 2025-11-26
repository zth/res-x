import { jsx as _jsx, jsxs as _jsxs } from "rescript-x/jsx-runtime";
import * as Htmx from "rescript-x/src/Htmx.js";
import { Actions } from "rescript-x/src/Client.js";
export function Home({ helloUrl, timeUrl }) {
    const swap = Htmx.Swap.make("innerHTML", "Transition");
    const actions = Actions.make([
        { kind: "ToggleClass", target: { kind: "This" }, className: "mt-2" },
    ]);
    return (_jsxs("div", { class: "box", children: [_jsx("h1", { children: "ResX + TSX Demo" }), _jsxs("p", { children: ["Rendered at: ", new Date().toISOString()] }), _jsx("div", { class: "mt-2", children: _jsx("button", { class: "btn", "hx-get": helloUrl, "hx-swap": swap, "resx-onclick": actions, children: "HTMX: Say Hello" }) }), _jsx("div", { class: "mt-2", children: _jsx("button", { class: "btn", "hx-get": timeUrl, "hx-swap": swap, children: "HTMX: Get Time" }) }), _jsx("div", { id: "htmx-target", class: "mt-2" })] }));
}
