@jsx.component
let make = () => {
  <input type_="hidden" name=CSRF.tokenInputName value={CSRF.generateToken()} />
}
