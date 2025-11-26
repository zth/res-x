export type Decision = "Allow" | { code?: number; message?: string } | boolean;

export type Handler<C> = (input: { request: Request; context: C }) =>
  | Decision
  | Promise<Decision>;

export const allow: Handler<any>;

