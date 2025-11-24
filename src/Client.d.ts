export namespace Actions {
  export type This = { kind: "This" };
  export type CssSelector = { kind: "CssSelector"; selector: string };
  export type Target = This | CssSelector;

  export type ToggleClass = {
    kind: "ToggleClass";
    target: Target;
    className: string;
  };
  export type RemoveClass = {
    kind: "RemoveClass";
    target: Target;
    className: string;
  };
  export type AddClass = {
    kind: "AddClass";
    target: Target;
    className: string;
  };
  export type SwapClass = {
    kind: "SwapClass";
    target: Target;
    fromClassName: string;
    toClassName: string;
  };
  export type RemoveElement = { kind: "RemoveElement"; target: Target };
  export type CopyToClipboard = {
    kind: "CopyToClipboard";
    text: string;
    onAfterSuccess?: Action[];
    onAfterFailure?: Action[];
  };

  export type Action =
    | ToggleClass
    | RemoveClass
    | AddClass
    | SwapClass
    | RemoveElement
    | CopyToClipboard;

  /**
   * Make the serialized actions string for the `resx-onclick` attribute.
   */
  export function make(actions: Action[]): string;
}

export namespace ValidityMessage {
  export interface Config {
    badInput?: string;
    patternMismatch?: string;
    rangeOverflow?: string;
    rangeUnderflow?: string;
    stepMismatch?: string;
    tooLong?: string;
    tooShort?: string;
    typeMismatch?: string;
    valueMissing?: string;
  }

  /**
   * Serialize validity messages for usage in the `resx-validity-message` attribute.
   */
  export function make(config: Config): string;
}

