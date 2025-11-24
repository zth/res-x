import type { ResxElement } from "./H.js";

export interface RequestController {
  setStatus(status: number): void;
  redirect(url: string, status?: number): void;
  getCurrentStatus(): number;
  getCurrentRedirect(): [string, number?] | undefined;
  getTitleSegments(): string[];
  getDocHeader(): string;
  setDocHeader(docHeader: string): void;
  appendToHead(
    content:
      | ResxElement
      | string
      | Array<ResxElement | string>
  ): void;
  appendBeforeBodyEnd(
    content:
      | ResxElement
      | string
      | Array<ResxElement | string>
  ): void;
  appendTitleSegment(segment: string): void;
  prependTitleSegment(segment: string): void;
  setFullTitle(title: string): void;
}

export function make(): RequestController;

