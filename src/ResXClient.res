@send
external addEventListener: (Dom.document, string, 'event => unit, ~capturePhase: bool=?) => unit =
  "addEventListener"
external document: Dom.document = "document"
external navigator: 'navigator = "navigator"

@send
external catchPromise: (promise<'a>, 'e => promise<'a>) => promise<'a> = "catch"

external querySelector: string => Null.t<'element> = "document.querySelector"

type validity = {
  badInput: bool,
  patternMismatch: bool,
  rangeOverflow: bool,
  rangeUnderflow: bool,
  stepMismatch: bool,
  tooLong: bool,
  tooShort: bool,
  typeMismatch: bool,
  valueMissing: bool,
  valid: bool,
}

type attr = {value: string}
type classList = {toggle: string => unit, add: string => unit, remove: string => unit}
type element = {
  "attributes": {"resx-onclick": option<attr>, "resx-validity-message": option<attr>},
  "classList": classList,
  "validity": option<validity>,
  "setCustomValidity": string => unit,
  "remove": unit => unit,
}
type event = {"target": element}

external parseActions: string => array<Client.Actions.action> = "JSON.parse"
external parseValidityMessage: string => Client.ValidityMessage.config = "JSON.parse"

(
  () => {
    let getTarget = (target: Client.Actions.target, this: element): Null.t<element> => {
      switch target {
      | This => Value(this)
      | CssSelector({selector}) => querySelector(selector)
      }
    }

    let rec handleAction = (action: Client.Actions.action, this) => {
      let target = switch action {
      | ToggleClass({target})
      | RemoveClass({target})
      | AddClass({target})
      | SwapClass({target})
      | RemoveElement({target}) =>
        getTarget(target, this)
      | CopyToClipboard(_) => Null
      }

      switch target {
      | Null => ()
      | Value(target) =>
        switch action {
        | ToggleClass({className}) => target["classList"].toggle(className)
        | RemoveClass({className}) => target["classList"].remove(className)
        | AddClass({className}) => target["classList"].add(className)
        | SwapClass({fromClassName, toClassName}) =>
          target["classList"].remove(fromClassName)
          target["classList"].add(toClassName)
        | RemoveElement(_) => target["remove"]()
        | CopyToClipboard({text, ?onAfterFailure, ?onAfterSuccess}) =>
          navigator["clipboard"]["writeText"](text)
          ->catchPromise(_ =>
            switch onAfterFailure {
            | None => Promise.resolve()
            | Some(actions) =>
              actions->Array.forEach(action => handleAction(action, this))->Promise.resolve
            }
          )
          ->Promise.thenResolve(_ =>
            switch onAfterSuccess {
            | None => ()
            | Some(actions) => actions->Array.forEach(action => handleAction(action, this))
            }
          )
          ->Promise.done
        }
      }
    }

    document->addEventListener("click", (event: event) => {
      let this = event["target"]
      let actions = switch this["attributes"]["resx-onclick"] {
      | None => []
      | Some({value}) => parseActions(value)
      }

      actions->Array.forEach(action => handleAction(action, this))
    })

    document->addEventListener("invalid", ~capturePhase=true, (event: event) => {
      let this = event["target"]
      switch (this["validity"], this["attributes"]["resx-validity-message"]) {
      | (Some({valid: false} as validity), Some({value})) =>
        let validityMessages = parseValidityMessage(value)
        let messageToSet = switch validity {
        | {badInput: true} => validityMessages.badInput
        | {patternMismatch: true} => validityMessages.patternMismatch
        | {rangeOverflow: true} => validityMessages.rangeOverflow
        | {rangeUnderflow: true} => validityMessages.rangeUnderflow
        | {stepMismatch: true} => validityMessages.stepMismatch
        | {tooLong: true} => validityMessages.tooLong
        | {tooShort: true} => validityMessages.tooShort
        | {typeMismatch: true} => validityMessages.typeMismatch
        | {valueMissing: true} => validityMessages.valueMissing
        | _ => None
        }
        switch messageToSet {
        | None => ()
        | Some(messageToSet) => this["setCustomValidity"](messageToSet)
        }
      | _ => ()
      }
    })

    document->addEventListener("change", (event: event) => {
      let this = event["target"]
      switch this["attributes"]["resx-validity-message"] {
      | Some(_) => this["setCustomValidity"]("")
      | None => ()
      }
    })
  }
)()
