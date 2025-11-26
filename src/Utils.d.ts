export namespace CacheControl {
  export type Time =
    | { TAG: "Seconds"; _0: number }
    | { TAG: "Minutes"; _0: number }
    | { TAG: "Hours"; _0: number }
    | { TAG: "Days"; _0: number }
    | { TAG: "Weeks"; _0: number }
    | { TAG: "Months"; _0: number }
    | { TAG: "Years"; _0: number };

  export type Expiration =
    | { kind: "max-age"; _0: Time }
    | { kind: "s-maxage"; _0: Time }
    | { kind: "max-stale"; _0: Time }
    | { kind: "min-fresh"; _0: Time };

  export type Revalidation =
    | "must-revalidate"
    | "proxy-revalidate"
    | { kind: "stale-while-revalidate"; _0: Time }
    | { kind: "stale-if-error"; _0: Time };

  export type Extension =
    | "must-understand"
    | "no-store-remote"
    | { _0: Time }; // wait-while-invalidate

  export function timeToString(t: Time): string;
  export function cacheabilityToString(c: string): string;
  export function expirationToString(e: Expiration): string;
  export function revalidationToString(r: Revalidation): string;
  export function modifiersToString(m: string): string;
  export function extensionsToString(e: Extension): string;

  export function make(
    noCache?: boolean,
    cacheability?: string,
    expiration?: Expiration[],
    revalidation?: Revalidation[],
    modifiers?: string[],
    extensions?: Extension[],
  ): string;

  export const Presets: {
    staticAssetsLongCache: string;
    frequentlyChangingContent: string;
    sensitiveContent: string;
    alwaysValidate: string;
    neverCache: string;
  };
}

