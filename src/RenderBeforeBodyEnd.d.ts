import type { ResxElement } from "./H.js";
import type { RequestController } from "./RequestController.js";

export function make(props: {
  requestController: RequestController;
  children?: ResxElement | ResxElement[] | string;
}): null;

