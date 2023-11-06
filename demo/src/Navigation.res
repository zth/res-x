@react.component
let make = () => {
  let context = HtmxHandler.useContext()

  <div>
    <a
      hxBoost=true
      className={U.tw([
        switch context.path {
        | list{"user", "1", ..._} => "font-bold"
        | _ => ""
        },
        "underline text-blue-700 visited:text-purple-700",
      ])}
      href="/user/1">
      {H.string("To User 1")}
    </a>
  </div>
}
