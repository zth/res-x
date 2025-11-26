// Type definitions for ResX H (server-side rendering and context)

export type ResxElement = unknown;

export namespace Context {
  export interface Instance<T> {
    id: string | number;
    Provider: (props: { value: T; children?: ResxElement }) => ResxElement;
  }

  /** Create a context. */
  export function createContext<T>(defaultValue: T): Instance<T>;
  /** Read a context value during render. */
  export function useContext<T>(instance: Instance<T>): T;
}

/** Render an element tree to an HTML string asynchronously. */
export function renderToString(element: ResxElement): Promise<string>;

/** Render an element tree to an HTML string synchronously. Throws if async content is encountered. */
export function renderSyncToString(element: ResxElement): string;

/** Render an element tree to a stream by emitting chunks via onChunk. Resolves when complete. */
export function renderToStream(
  element: ResxElement,
  onChunk?: (chunk: string) => void
): Promise<void>;
