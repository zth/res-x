export const isDev: boolean;

export function serveStaticFile(request: Request): Promise<Response | undefined>;

export function runDevServer(port: number): void;

export namespace URLSearchParams {
  function copy(search: globalThis.URLSearchParams): globalThis.URLSearchParams;
}

