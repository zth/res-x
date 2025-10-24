module Actions: {
  type t

  @tag("kind")
  type target = This | CssSelector({selector: string})

  @tag("kind")
  type rec action =
    | ToggleClass({target: target, className: string})
    | RemoveClass({target: target, className: string})
    | AddClass({target: target, className: string})
    | SwapClass({target: target, fromClassName: string, toClassName: string})
    | RemoveElement({target: target})
    | CopyToClipboard({
        text: string,
        onAfterSuccess?: array<action>,
        onAfterFailure?: array<action>,
      })

  let make: array<action> => t
} = {
  type t = string

  @tag("kind")
  type target = This | CssSelector({selector: string})

  @tag("kind")
  type rec action =
    | ToggleClass({target: target, className: string})
    | RemoveClass({target: target, className: string})
    | AddClass({target: target, className: string})
    | SwapClass({target: target, fromClassName: string, toClassName: string})
    | RemoveElement({target: target})
    | CopyToClipboard({
        text: string,
        onAfterSuccess?: array<action>,
        onAfterFailure?: array<action>,
      })

  external stringifyActions: array<action> => string = "JSON.stringify"

  let make = actions => stringifyActions(actions)
}

module ValidityMessage: {
  type config = {
    badInput?: string,
    patternMismatch?: string,
    rangeOverflow?: string,
    rangeUnderflow?: string,
    stepMismatch?: string,
    tooLong?: string,
    tooShort?: string,
    typeMismatch?: string,
    valueMissing?: string,
  }

  type t

  let make: config => t
} = {
  type config = {
    badInput?: string,
    patternMismatch?: string,
    rangeOverflow?: string,
    rangeUnderflow?: string,
    stepMismatch?: string,
    tooLong?: string,
    tooShort?: string,
    typeMismatch?: string,
    valueMissing?: string,
  }

  type t = string

  external stringifyConfig: config => string = "JSON.stringify"

  let make = config => stringifyConfig(config)
}
