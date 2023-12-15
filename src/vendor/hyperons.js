// Inlined from https://github.com/zth/hyperons (built)
let id = 0;
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
const Fragment = Symbol("Fragment");
const UPPERCASE = /([A-Z])/g;
const MS = /^ms-/;
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
const ESCAPE_REGEXP = /["'&<>]/g;
const ESCAPE_MAP = {
  '"': "&quot;",
  "'": "&#39;",
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
};
function escapeChar(char) {
  return ESCAPE_MAP[char];
}
function escapeString(value) {
  if (!ESCAPE_REGEXP.test(value)) {
    return value;
  }
  return String(value).replace(ESCAPE_REGEXP, escapeChar);
}
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
  dispatcher.context = context;
  if (typeof element === "string") {
    return controller.content.push(escapeString(element));
  } else if (typeof element === "number") {
    return controller.content.push(String(element));
  } else if (typeof element === "boolean" || element == null) {
    return;
  } else if (Array.isArray(element)) {
    return element.forEach((e) => renderToString(e, context, controller));
  } else if (element instanceof Promise) {
    return controller.handleAsync(element, context, controller);
  }
  const type = element.type;
  if (type) {
    const props = element.props || EMPTY_OBJECT;
    if (type.contextRef) {
      context = Object.assign({}, context, {
        [type.contextRef.id]: props.value,
      });
      if (type.contextRef.id === "errorBoundary") {
        try {
          return controller.content.push(
            renderToString(type(props), context, controller)
          );
        } catch (e) {
          return controller.content.push(
            renderToString(context["errorBoundary"](e), context, controller)
          );
        }
      }
    }
    if (typeof type === "function") {
      return renderToString(type(props), context, controller);
    }
    if (type === Fragment) {
      return renderToString(props.children, context, controller);
    }
    if (typeof type === "string") {
      let html = `<${type}`;
      let innerHTML;
      for (const prop in props) {
        const value = props[prop];
        if (prop === "children" || prop === "key" || prop === "ref");
        else if (prop === "class" || prop === "className") {
          html += value ? ` class="${escapeString(value)}"` : "";
        } else if (prop === "style") {
          html += ` style="${stringifyStyles(value)}"`;
        } else if (prop.startsWith("resx-")) {
          html += ` ${prop}='${value}'`;
        } else if (prop === "dangerouslySetInnerHTML") {
          innerHTML = value.__html;
        } else {
          const name = ATTR_ALIASES[prop] || prop;
          if (BOOLEAN_ATTRS.has(name)) {
            html += value ? ` ${name}` : "";
          } else if (typeof value === "string") {
            html += ` ${name}="${escapeString(value)}"`;
          } else if (typeof value === "number") {
            html += ` ${name}="${String(value)}"`;
          } else if (typeof value === "boolean") {
            html += ` ${name}="${value}"`;
          }
        }
      }
      if (VOID_ELEMENTS.has(type)) {
        html += "/>";
        return controller.content.push(html);
      } else {
        html += ">";
        if (innerHTML) {
          html += innerHTML;
          controller.content.push(html);
        } else {
          controller.content.push(html);
          renderToString(props.children, context, controller);
        }
        controller.content.push(`</${type}>`);
      }
      return;
    }
  }
}
function makeController(onChunk) {
  const controller = {
    content: [],
    onChunk,
    hasAsync: false,
    handleAsync(promise, context, controller2) {
      this.hasAsync = true;
      if (controller2.onChunk != null) {
        controller2.onChunk(this.content.join(""));
        this.content = [];
      }
      this.content.push({ promise, context, controller: controller2 });
    },
  };
  return controller;
}
async function renderController(controller) {
  if (controller.hasAsync) {
    return (
      await Promise.all(
        controller.content.map(async (item) => {
          if (item == null) return "";
          if (typeof item === "string") return item;
          const controller2 = makeController(controller.onChunk);
          const element = await item.promise;
          renderToString(element, item.context, controller2);
          return await renderController(controller2);
        })
      )
    ).join("");
  } else {
    return controller.content.join("");
  }
}
async function render(element, onChunk) {
  const controller = makeController(onChunk);
  renderToString(element, {}, controller);
  const res = await renderController(controller);
  if (onChunk != null) {
    onChunk(res);
  } else {
    return res;
  }
}
function useContext(instance) {
  return instance.getChildContext(dispatcher.context);
}
export {
  Fragment,
  createContext,
  createElement as h,
  render,
  useContext,
  escapeString,
};
