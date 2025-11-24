import type { ResxElement } from "./H.js";

export type ErrorRenderer = (error: unknown) => ResxElement;
export function make(props: { children?: ResxElement; renderError: ErrorRenderer }): ResxElement;

