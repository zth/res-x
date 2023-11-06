let expectCheckbox = (t, name) => {
  t->FormData.expectCustom(name, ~decoder=res =>
    switch res {
    | String("on") => Ok(true)
    | _ => Ok(false)
    }
  )
}

let expectDate = (t, name) => {
  t->FormData.expectCustom(name, ~decoder=res =>
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
