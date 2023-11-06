let wait = () =>
  Promise.make((resolve, _reject) => {
    let _timeoutId = setTimeout(() => {
      resolve()
    }, 1000)
  })

@react.component
let make = async (~children) => {
  await wait()
  <div>
    {H.string("This was deferred.")}
    <div> {children} </div>
  </div>
}
