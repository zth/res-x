export namespace Swap {
  export type t = string;
  export type Modifier =
    | "Transition"
    | { TAG: "Swap"; _0: string }
    | { TAG: "Settle"; _0: string }
    | { TAG: "Scroll"; _0: "top" | "bottom" }
    | { TAG: "ScrollWithSelector"; _0: string; _1: "top" | "bottom" }
    | { TAG: "Show"; _0: "top" | "bottom" }
    | { TAG: "ShowWithSelector"; _0: string; _1: "top" | "bottom" };
  export function make(swap: string, modifier?: Modifier): t;
}

export namespace Target {
  export type t = string;
  export function make(target: any): t;
}

export namespace Params {
  export type t = string;
  export function make(p: any): t;
}

export namespace Encoding {
  export type t = string;
  export function make(encoding: any): t;
}

export namespace Indicator {
  export type t = string;
  export function make(indicator: any): t;
}

export namespace Headers {
  export type t = string;
  export function make(dict: Record<string, string>): t;
}

export namespace Sync {
  export type t = string;
  export function make(c: any): t;
}

export namespace Vals {
  export type t = string;
  export function make(vals: any): t;
}

export namespace Disinherit {
  export type t = string;
  export function make(disinherit: any): t;
}

