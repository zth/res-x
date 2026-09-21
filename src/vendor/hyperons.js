// Inlined from https://github.com/zth/hyperons (built)
let id = 0;

const RAW = Symbol("Raw");
function createRaw(content) {
  return { [RAW]: content };
}

class Context {
  constructor(defaultValue, forceId) {
    this.id = forceId != null ? forceId : id++;
    this.defaultValue = defaultValue;
    this.Provider = this.Provider.bind(this);
    this.Provider.contextRef = this;
  }
  getChildContext(context) {
    return Object.hasOwnProperty.call(context, this.id)
      ? context[this.id]
      : this.defaultValue;
  }
  Provider(props) {
    return props.children;
  }
}
function createContext(defaultValue, forceId) {
  return new Context(defaultValue, forceId);
}
function createElement(type, props, ...children) {
  props = props || {};
  props.children =
    children.length === 0 && props.children ? props.children : children;
  return { type, props };
}
// ReScript JSX already supplies children in props. Unlike the legacy h()
// API this path needs no rest arguments, child arrays, or props mutation.
// Components remain deferred so providers and request context work as before.
function jsx(type, props) {
  return { type, props };
}
const Fragment = Symbol("Fragment");
const UPPERCASE = /([A-Z])/g;
const MS = /^ms-/;
const VALID_RAW_ATTR_NAME = /^[A-Za-z_:][A-Za-z0-9:._-]*$/;
const UNITLESS_PROPS = /* @__PURE__ */ new Set([
  "animationIterationCount",
  "columns",
  "columnCount",
  "flex",
  "flexGrow",
  "flexShrink",
  "fontWeight",
  "gridColumn",
  "gridColumnEnd",
  "gridColumnStart",
  "gridRow",
  "gridRowEnd",
  "gridRowStart",
  "lineHeight",
  "opacity",
  "order",
  "orphans",
  "tabSize",
  "widows",
  "zIndex",
  "zoom",
]);
const CACHE = {};
function hyphenateChar(char) {
  return "-" + char.toLowerCase();
}
function hyphenateString(prop) {
  return prop.replace(UPPERCASE, hyphenateChar).replace(MS, "-ms-");
}
function stringifyStyles(styles) {
  let out = "";
  for (let prop in styles) {
    const value = styles[prop];
    if (value != null) {
      const unit =
        typeof value === "number" && value !== 0 && !UNITLESS_PROPS.has(prop)
          ? "px"
          : "";
      prop = CACHE[prop] || (CACHE[prop] = hyphenateString(prop));
      out += `${prop}:${value}${unit};`;
    }
  }
  return out;
}
function normalizeRawAttributeName(key) {
  const name = String(key).trim();
  if (name === "" || !VALID_RAW_ATTR_NAME.test(name)) {
    return undefined;
  }
  return name;
}
function stringifyAttributeValue(value) {
  if (value === null) {
    return "null";
  }
  switch (typeof value) {
    case "string":
    case "number":
    case "boolean":
      return String(value);
    default:
      return JSON.stringify(value);
  }
}
const escapeString = Bun.escapeHTML;
const dispatcher = {};
const ATTR_ALIASES = {
  acceptCharset: "acceptcharset",
  accessKey: "accesskey",
  allowFullScreen: "allowfullscreen",
  autoCapitalize: "autocapitalize",
  autoComplete: "autocomplete",
  autoCorrect: "autocorrect",
  autoFocus: "autofocus",
  autoPlay: "autoplay",
  charSet: "charset",
  className: "class",
  colSpan: "colspan",
  contentEditable: "contenteditable",
  crossOrigin: "crossorigin",
  dateTime: "datetime",
  defaultChecked: "checked",
  defaultSelected: "selected",
  defaultValue: "value",
  htmlFor: "for",
  httpEquiv: "http-equiv",
  longDesc: "longdesc",
  maxLength: "maxlength",
  minLength: "minlength",
  noModule: "nomodule",
  noValidate: "novalidate",
  readOnly: "readonly",
  referrerPolicy: "referrerpolicy",
  rowSpan: "rowspan",
  spellCheck: "spellcheck",
  tabIndex: "tabindex",
  useMap: "usemap",
};
const BOOLEAN_ATTRS = /* @__PURE__ */ new Set([
  "async",
  "allowfullscreen",
  "allowpaymentrequest",
  "autofocus",
  "autoplay",
  "checked",
  "controls",
  "default",
  "defer",
  "disabled",
  "formnovalidate",
  "hidden",
  "ismap",
  "multiple",
  "muted",
  "novalidate",
  "nowrap",
  "open",
  "readonly",
  "required",
  "reversed",
  "selected",
]);
const VOID_ELEMENTS = /* @__PURE__ */ new Set([
  "area",
  "base",
  "br",
  "col",
  "embed",
  "hr",
  "img",
  "input",
  "link",
  "meta",
  "param",
  "source",
  "track",
  "wbr",
]);
const EMPTY_OBJECT = Object.freeze({});
function renderToString(element, context = {}, controller) {
  // Check for raw HTML objects first
  if (element && typeof element === "object" && RAW in element) {
    controller.content += element[RAW];
    return;
  }

  if (typeof element === "string") {
    controller.content += escapeString(element);
    return;
  } else if (typeof element === "number") {
    controller.content += String(element);
    return;
  } else if (typeof element === "boolean" || element == null) {
    return;
  } else if (Array.isArray(element)) {
    for (let i = 0; i < element.length; i++) {
      renderToString(element[i], context, controller);
    }
    return;
  } else if (element instanceof Promise) {
    return controller.handleAsync(element, context, controller);
  }
  const type = element.type;
  if (type) {
    const props = element.props || EMPTY_OBJECT;
    if (type.contextRef) {
      dispatcher.context = context;
      context = Object.assign({}, context, {
        [type.contextRef.id]: props.value,
      });
      if (type.contextRef.id === "errorBoundary") {
        try {
          return renderToString(type(props), context, controller);
        } catch (e) {
          return renderToString(context["errorBoundary"](e), context, controller);
        }
      }
    }
    if (typeof type === "function") {
      dispatcher.context = context;
      return renderToString(type(props), context, controller);
    }
    if (type === Fragment) {
      return renderToString(props.children, context, controller);
    }
    if (typeof type === "string") {
      let html = `<${type}`;
      let innerHTML;
      let rawProps;
      for (const prop in props) {
        const value = props[prop];
        if (prop === "children" || prop === "key" || prop === "ref");
        else if (prop === "__rawProps") {
          rawProps = value;
        } else if (prop === "class" || prop === "className") {
          if (value) {
            html += ` class="${escapeString(value)}"`;
          }
        } else if (prop === "style") {
          html += ` style="${stringifyStyles(value)}"`;
        } else if (prop.startsWith("resx-")) {
          html += ` ${prop}='${value}'`;
        } else if (prop === "dangerouslySetInnerHTML") {
          innerHTML = value.__html;
        } else {
          const name = ATTR_ALIASES[prop] || prop;
          if (BOOLEAN_ATTRS.has(name)) {
            if (value) {
              html += ` ${name}`;
            }
          } else if (typeof value === "string") {
            html += ` ${name}="${escapeString(value)}"`;
          } else if (typeof value === "number") {
            html += ` ${name}="${String(value)}"`;
          } else if (typeof value === "boolean") {
            html += ` ${name}="${value}"`;
          }
        }
      }
      if (rawProps != null) {
        for (const [key, value] of Object.entries(rawProps)) {
          const name = normalizeRawAttributeName(key);
          if (name == null) {
            continue;
          }
          const serialized = stringifyAttributeValue(value);
          html += ` ${name}="${escapeString(serialized)}"`;
        }
      }
      if (VOID_ELEMENTS.has(type)) {
        html += "/>";
        controller.content += html;
        return;
      } else {
        html += ">";
        const children = props.children;
        // Text leaves are common: append the complete element without
        // another recursive call.
        if (innerHTML) {
          html += innerHTML;
        } else if (typeof children === "string") {
          html += escapeString(children);
        } else if (typeof children === "number") {
          html += String(children);
        } else if (children != null && typeof children !== "boolean") {
          controller.content += html;
          renderToString(children, context, controller);
          controller.content += `</${type}>`;
          return;
        }
        controller.content += html + `</${type}>`;
      }
      return;
    }
  }
}
function makeController(onChunk) {
  const controller = {
    content: "",
    pending: null,
    onChunk,
    hasAsync: false,
    handleAsync(promise, context, controller2) {
      // Only the prefix before the first async subtree is ready to stream.
      // Later siblings must remain buffered until preceding promises settle.
      if (!this.hasAsync) {
        this.pending = [];
        if (controller2.onChunk != null) {
          controller2.onChunk(this.content);
          this.content = "";
        }
        this.hasAsync = true;
      }
      this.pending.push(this.content, { promise, context });
      this.content = "";
    },
  };
  return controller;
}
function renderAsyncItem(item) {
  return item.promise.then(element => {
    const child = makeController();
    renderToString(element, item.context, child);
    return renderController(child);
  });
}
function renderController(controller) {
  if (!controller.hasAsync) return controller.content;
  const content = controller.pending;
  content.push(controller.content);
  // One async child is common (for example a page with an async footer).
  // There is no fan-out to coordinate in this case.
  if (content.length === 3) {
    return renderAsyncItem(content[1]).then(html => content[0] + html + content[2]);
  }
  const pending = [];
  for (let i = 0; i < content.length; i++) {
    const item = content[i];
    if (item == null || typeof item === "string" || typeof item === "number") continue;
    // Only async subtrees need promises. Each static span stays a string,
    // regardless of how many HTML elements it contains.
    pending.push(item.promise.then(element => {
      const child = makeController();
      renderToString(element, item.context, child);
      const rendered = renderController(child);
      if (typeof rendered === "string") {
        content[i] = rendered;
      } else {
        return rendered.then(html => { content[i] = html; });
      }
    }));
  }
  return Promise.all(pending).then(() => content.join(""));
}
async function render(element, onChunk) {
  const controller = makeController(onChunk);
  renderToString(element, {}, controller);
  // Preserve the promise-returning API without suspending for a sync tree.
  // Callback rendering still crosses the await boundary as before.
  if (!controller.hasAsync && onChunk == null) return controller.content;
  const res = await renderController(controller);
  if (onChunk != null) {
    onChunk(res);
  } else {
    return res;
  }
}
function renderSync(element) {
  const controller = makeController();
  renderToString(element, {}, controller);
  if (controller.hasAsync) {
    throw new Error("Tried to render async tree sync.");
  } else {
    return controller.content;
  }
}
function useContext(instance) {
  return instance.getChildContext(dispatcher.context);
}
export {
  Fragment,
  createContext,
  createElement as h,
  jsx,
  render,
  renderSync,
  useContext,
  escapeString,
  createRaw,
};
