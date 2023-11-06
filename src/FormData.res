type t

@unboxed type formDataValue = String(string) | File(Js.File.t)
@unboxed type formDataValueResult = | ...formDataValue | @as(null) Null

@send external get: (t, string) => formDataValueResult = "get"
@send external getAll: (t, string) => array<formDataValue> = "getAll"

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

let getString = (t, name) =>
  switch t->get(name) {
  | String(s) => Some(s)
  | _ => None
  }
let getInt = (t, name) => t->getString(name)->Option.flatMap(s => s->Int.fromString)
let getFloat = (t, name) => t->getString(name)->Option.flatMap(s => s->Float.fromString)
let getBool = (t, name) =>
  switch t->get(name) {
  | String("true") => Some(true)
  | String("false") => Some(false)
  | _ => None
  }

let getStringArray = (t, name) =>
  t
  ->getAll(name)
  ->Array.map(v =>
    switch v {
    | String(s) => Some(s)
    | _ => None
    }
  )
  ->Array.keepSome

let getIntArray = (t, name) =>
  t
  ->getAll(name)
  ->Array.map(v =>
    switch v {
    | String(s) => s->Int.fromString
    | _ => None
    }
  )
  ->Array.keepSome

let getFloatArray = (t, name) =>
  t
  ->getAll(name)
  ->Array.map(v =>
    switch v {
    | String(s) => s->Float.fromString
    | _ => None
    }
  )
  ->Array.keepSome

let getBoolArray = (t, name) =>
  t
  ->getAll(name)
  ->Array.map(v =>
    switch v {
    | String("true") => Some(true)
    | String("false") => Some(false)
    | _ => None
    }
  )
  ->Array.keepSome

let getCustom = (t, name, ~decoder): result<'value, 'error> => t->get(name)->decoder

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
