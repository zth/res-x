/** Represents the result of a security policy evaluation. */
type securityPolicy<'securityPolicyData> =
  /** Permits the request to proceed with metadata for the handler. */
  | Allow('securityPolicyData)
  /** Blocks the request with optional error code and message. */
  | Block({code: option<int>, message: option<string>})

type handlerConfig<'ctx> = {
  request: Request.t,
  context: 'ctx,
}

type handler<'ctx, 'securityPolicyData> = handlerConfig<'ctx> => promise<
  securityPolicy<'securityPolicyData>,
>

/** Allow all requests.*/
let allow = async _ => Allow()
