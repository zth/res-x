// Type definitions for ResX Hjsx runtime (TSX support)

export type ResxRenderable = ResxElement | Promise<ResxElement>;
export type ResxElement = unknown;

export type ComponentType<P> = (props: P) => ResxRenderable;
export type PropsOf<T> = T extends ComponentType<infer P>
  ? P
  : Record<string, unknown>;

export const jsxFragment: symbol;

/** Output literal HTML. Use with care; content is not escaped. */
export function dangerouslyOutputUnescapedContent(html: string): ResxElement;

/** JSX factory for single-child elements (automatic/classic TSX usage). */
export function jsx<T>(type: T, props: PropsOf<T>): ResxElement;

/** JSX factory for multi-child elements (automatic/classic TSX usage). */
export function jsxs<T>(type: T, props: PropsOf<T>): ResxElement;

export namespace Elements {
  function jsx<T>(type: T, props: PropsOf<T>): ResxElement;
  function jsxs<T>(type: T, props: PropsOf<T>): ResxElement;
}

// Minimal JSX namespace to enable TSX
export namespace JSX {
  type Element = ResxElement;
  interface IntrinsicElements {
    [elemName: string]: Record<string, unknown>;
  }

  // Explicitly declare the name of the children prop
  interface ElementChildrenAttribute {
    children: {};
  }
}

// (Types only) Runtime exports are provided by the actual JS files via package exports
