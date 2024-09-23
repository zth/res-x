let getOrRaise = (opt, ~name, ~expectedType, ~message=?) =>
  switch opt {
  | None =>
    panic(
      switch message {
      | None => `Expected "${name}" to be ${expectedType}, but got something else.`
      | Some(message) => message
      },
    )
  | Some(v) => v
  }

let getString = (t, name, ~allowEmptyString=false) =>
  switch t->FormData.get(name) {
  | String(s) =>
    switch s {
    | "" if allowEmptyString => Some("")
    | _ => Some(s)
    }
  | _ => None
  }

let getInt = (t, name) => t->getString(name)->Option.flatMap(s => s->Int.fromString)
let getFloat = (t, name) => t->getString(name)->Option.flatMap(s => s->Float.fromString)
let getBool = (t, name) =>
  switch t->FormData.get(name) {
  | String("true" | "on") => Some(true)
  | String("false" | "off") => Some(false)
  | _ => None
  }

let getStringArray = (t, name) =>
  t
  ->FormData.getAll(name)
  ->Array.map(v =>
    switch v {
    | String(s) => Some(s)
    | _ => None
    }
  )
  ->Array.keepSome

let getIntArray = (t, name) =>
  t
  ->FormData.getAll(name)
  ->Array.map(v =>
    switch v {
    | String(s) => s->Int.fromString
    | _ => None
    }
  )
  ->Array.keepSome

let getFloatArray = (t, name) =>
  t
  ->FormData.getAll(name)
  ->Array.map(v =>
    switch v {
    | String(s) => s->Float.fromString
    | _ => None
    }
  )
  ->Array.keepSome

let getBoolArray = (t, name) =>
  t
  ->FormData.getAll(name)
  ->Array.map(v =>
    switch v {
    | String("true") => Some(true)
    | String("false") => Some(false)
    | _ => None
    }
  )
  ->Array.keepSome

let getCustom = (t, name, ~decoder): result<'value, 'error> => t->FormData.get(name)->decoder

let expectCustom = (t, name, ~decoder) =>
  switch t->getCustom(name, ~decoder) {
  | Error(message) => panic(message)
  | Ok(v) => v
  }
let expectString = (t, name, ~message=?) =>
  t->getString(name)->getOrRaise(~expectedType="string", ~name, ~message?)
let expectInt = (t, name, ~message=?) =>
  t->getInt(name)->getOrRaise(~expectedType="int", ~name, ~message?)
let expectFloat = (t, name, ~message=?) =>
  t->getFloat(name)->getOrRaise(~expectedType="float", ~name, ~message?)
let expectBool = (t, name, ~message=?) =>
  t->getBool(name)->getOrRaise(~expectedType="bool", ~name, ~message?)

let expectCheckbox = (t, name) => {
  t->expectCustom(name, ~decoder=res =>
    switch res {
    | String("on") => Ok(true)
    | _ => Ok(false)
    }
  )
}

let expectDate = (t, name) => {
  t->expectCustom(name, ~decoder=res =>
    switch res {
    | String(d) =>
      let date = Date.fromString(d)
      if date->Date.getTime->Float.isNaN {
        Error("Invalid date.")
      } else {
        Ok(date)
      }
    | _ => Error("Invalid date.")
    }
  )
}
