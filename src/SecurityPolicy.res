/** Represents the result of a security policy evaluation. */
type securityPolicy =
  | /** Permits the request to proceed. */ Allow
  | /** Blocks the request with optional error code and message. */
  Block({
      code: option<int>,
      message: option<string>,
    })

type handlerConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
}

type handler<'ctx> = handlerConfig<'ctx> => promise<securityPolicy>

/** Allow all requests.*/
let allow = async _ => Allow
