let tokenInputName = "resx_csrf_token"

let getTokenFromHeaders = headers =>
  switch headers->Headers.get("x-csrf-token") {
  | Some(v) => Some(v)
  | None => None
  }

let getTokenFromRequest = async (request: Request.t) => {
  switch request->Request.headers->getTokenFromHeaders {
  | Some(v) => Some(v)
  | None =>
    switch request->Request.headers->Headers.get("Content-Type") {
    | Some(ct)
      if ct->String.includes("application/x-www-form-urlencoded") ||
        ct->String.includes("multipart/form-data") =>
      let fd = await request->Request.clone->Request.formData
      switch fd->FormData.get(tokenInputName) {
      | String(v) => Some(v)
      | _ => None
      }
    | _ => None
    }
  }
}

let getSecret = () => Bun.env->Bun.Env.get("RESX_CSRF_SECRET")

let generateToken = () =>
  switch getSecret() {
  | Some(secret) => Bun.CSRF.generateWithSecret(secret)
  | None => Bun.CSRF.generate()
  }

let verifyRequest = async (request: Request.t) =>
  switch await request->getTokenFromRequest {
  | Some(token) =>
    switch getSecret() {
    | Some(secret) => Bun.CSRF.verifyWithOptions(token, {secret: secret})
    | None => Bun.CSRF.verify(token)
    }
  | None => false
  }
