let match = (userRoutes, ~headers, ~requestController: ResX.RequestController.t) => {
  requestController.appendTitleSegment("Users")

  switch userRoutes {
  | list{userId, ...userRoutes} =>
    requestController.appendTitleSegment(userId)
    headers->Headers.set("Cache-Control", "private")
    <UserPage
      userId
      innerContent={switch userRoutes {
      | list{"friends"} => <UserFriends userId />
      | _ => Hjsx.null
      }}
    />
  | _ =>
    requestController.appendTitleSegment("Not found")
    <FourOhFour />
  }
}
