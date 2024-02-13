let wait = () =>
  Promise.make((resolve, _reject) => {
    let _timeoutId = setTimeout(() => {
      resolve()
    }, 1000)
  })

@jsx.component
let make = async (~children) => {
  await wait()
  <div>
    {Hjsx.string("This was deferred.")}
    <div> {children} </div>
  </div>
}
