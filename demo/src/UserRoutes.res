let match = (userRoutes, ~headers, ~requestController) => {
  open Bun

  requestController->ResX.RequestController.appendTitleSegment("Users")

  switch userRoutes {
  | list{userId, ...userRoutes} =>
    requestController->ResX.RequestController.appendTitleSegment(userId)
    headers->Headers.set("Cache-Control", "private")
    <UserPage
      userId
      innerContent={switch userRoutes {
      | list{"friends"} => <UserFriends userId />
      | _ => H.null
      }}
    />
  | _ =>
    requestController->ResX.RequestController.appendTitleSegment("Not found")
    <FourOhFour />
  }
}
