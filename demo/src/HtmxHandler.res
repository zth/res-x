type context = {userId: option<string>}

let handler = ResX.Handlers.make(~requestToContext=async _request => {
  userId: None,
})

let useContext = () => handler->ResX.Handlers.useContext
