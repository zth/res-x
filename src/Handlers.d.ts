import type { RequestController } from "./RequestController.js";
import type { ResxElement } from "./H.js";

export type SecurityPolicyDecision =
  | boolean
  | { code?: number; message?: string }
  | "Allow"
  | "Block";
export type SecurityPolicy<C> = (
  input: { request: Request; context: C }
) => SecurityPolicyDecision | Promise<SecurityPolicyDecision>;

export type HxHandler<C> = (input: {
  request: Request;
  context: C;
  headers: Headers;
  requestController: RequestController;
}) => ResxElement | Promise<ResxElement>;

export type FormActionHandler<C> = (input: {
  request: Request;
  context: C;
}) => Response | Promise<Response>;

export type DefaultCsrfCheck =
  | { TAG: "ForAllMethods"; _0: boolean }
  | { get?: boolean; post?: boolean; put?: boolean; delete?: boolean; patch?: boolean };

export interface MakeOptions {
  htmxApiPrefix?: string;
  formActionHandlerApiPrefix?: string;
  defaultCsrfCheck?: DefaultCsrfCheck;
}

export interface RenderConfig<C> {
  request: Request;
  headers: Headers;
  context: C;
  path: string[];
  url: URL;
  requestController: RequestController;
}

export interface Handlers<C> {
  // Opaque internal type; used with exported functions
  readonly _brand?: C;
}

export function make<C>(
  requestToContext: (req: Request) => Promise<C>,
  options?: MakeOptions
): Handlers<C>;

export function useContext<C>(handlers: Handlers<C>): RenderConfig<C> | undefined;

export interface HandleRequestConfig<C> {
  request: Request;
  render: (config: RenderConfig<C>) => ResxElement | Promise<ResxElement>;
  renderTitle?: (segments: string[]) => string;
  setupHeaders?: () => Headers;
  onBeforeBuildResponse?: (input: {
    request: Request;
    context: C;
    responseType: "Default" | "HtmxHandler" | "FormActionHandler";
    requestController: RequestController;
  }) => void | Promise<void>;
  onAfterBuildResponse?: (input: {
    request: Request;
    context: C;
    responseType: "Default" | "HtmxHandler" | "FormActionHandler";
    requestController: RequestController;
  }) => void | Promise<void>;
  onBeforeSendResponse?: (input: {
    request: Request;
    response: Response;
    context: C;
    responseType: "Default" | "HtmxHandler" | "FormActionHandler";
  }) => Response | Promise<Response>;
  experimental_stream?: boolean;
}

export function handleRequest<C>(
  handlers: Handlers<C>,
  config: HandleRequestConfig<C>
): Promise<Response>;

export function formAction<C>(
  handlers: Handlers<C>,
  path: string,
  securityPolicy: SecurityPolicy<C>,
  handler: FormActionHandler<C>,
  csrfCheck?: boolean
): string;

export declare namespace FormAction {
  function string(path: string): string;
  function toEndpointURL(path: string): string;
}

export function hxGet<C>(
  handlers: Handlers<C>,
  path: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): string;
export function hxGetRef<C>(handlers: Handlers<C>, path: string): string;
export function hxGetDefine<C>(
  handlers: Handlers<C>,
  pathRef: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): void;
export function hxGetToEndpointURL(path: string): string;

export function hxPost<C>(
  handlers: Handlers<C>,
  path: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): string;
export function hxPostRef<C>(handlers: Handlers<C>, path: string): string;
export function hxPostDefine<C>(
  handlers: Handlers<C>,
  pathRef: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): void;
export function hxPostToEndpointURL(path: string): string;

export function hxPut<C>(
  handlers: Handlers<C>,
  path: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): string;
export function hxPutRef<C>(handlers: Handlers<C>, path: string): string;
export function hxPutDefine<C>(
  handlers: Handlers<C>,
  pathRef: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): void;
export function hxPutToEndpointURL(path: string): string;

export function hxDelete<C>(
  handlers: Handlers<C>,
  path: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): string;
export function hxDeleteRef<C>(handlers: Handlers<C>, path: string): string;
export function hxDeleteDefine<C>(
  handlers: Handlers<C>,
  pathRef: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): void;
export function hxDeleteToEndpointURL(path: string): string;

export function hxPatch<C>(
  handlers: Handlers<C>,
  path: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): string;
export function hxPatchRef<C>(handlers: Handlers<C>, path: string): string;
export function hxPatchDefine<C>(
  handlers: Handlers<C>,
  pathRef: string,
  securityPolicy: SecurityPolicy<C>,
  handler: HxHandler<C>,
  csrfCheck?: boolean
): void;
export function hxPatchToEndpointURL(path: string): string;

export declare namespace Internal {
  // Internal utilities not intended for public consumption
}
