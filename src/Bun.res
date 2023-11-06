// This must only have zero cost bindings. The rest goes into `BunUtils.res`.

module ReadableStream = {
  type t
}

module BunFile = {
  type t

  @send external text: t => promise<string> = "text"
  @get external size: t => float = "size"
}

external file: string => BunFile.t = "Bun.file"

module HeadersInit = {
  @unboxed type t = FromArray(array<(string, string)>) | FromDict(Js.Dict.t<string>)
}

/**
 * This Fetch API interface allows you to perform various actions on HTTP
 * request and response headers. These actions include retrieving, setting,
 * adding to, and removing. A Headers object has an associated header list,
 * which is initially empty and consists of zero or more name and value
 * pairs.
 *
 * You can add to this using methods like append()
 *
 * In all methods of this interface, header names are matched by
 * case-insensitive byte sequence.
 */
module Headers = {
  type t

  @new external make: unit => t = "Headers"
  @new external makeWithInit: HeadersInit.t => t = "Headers"

  @send external append: (t, string, string) => unit = "append"
  @send external delete: (t, string) => unit = "delete"
  @return(nullable) @send external get: (t, string) => option<string> = "get"
  @send external has: (t, string) => bool = "has"
  @send external set: (t, string, string) => unit = "set"
  @send external entries: t => Iterator.t<(string, string)> = "entries"
  @send external keys: t => Iterator.t<string> = "keys"
  @send external values: t => Iterator.t<string> = "values"
  @send external forEach: (t, (string, string, t) => unit) => unit = "forEach"

  /**
   * Convert {@link Headers} to a plain JavaScript object.
   *
   * About 10x faster than `Object.fromEntries(headers.entries())`
   *
   * Called when you run `JSON.stringify(headers)`
   *
   * Does not preserve insertion order. Well-known header names are lowercased. Other header names are left as-is.
   */
  @send
  external toJSON: t => Dict.t<string> = "toJSON"

  /**
   * Get the total number of headers
   */
  @get
  external count: t => int = "count"

  /**
   * Get all headers matching "Set-Cookie"
   *
   * Only supports `"Set-Cookie"`. All other headers are empty arrays.
   *
   * @returns An array of header values
   *
   * @example
   * ```rescript
   * let headers = Headers.make()
   * headers->Headers.append("Set-Cookie", "foo=bar")
   * headers->Headers.append("Set-Cookie", "baz=qux")
   * let cookies = headers->Headers.getAllCookies // ["foo=bar", "baz=qux"]
   * ```
   */
  @send
  external getAllCookies: (t, @as("Set-Cookie") _) => array<string> = "getAll"
}

/** All possible HTTP methods. */
type method = GET | HEAD | POST | PUT | DELETE | CONNECT | OPTIONS | TRACE | PATCH

module URLSearchParams = {
  type t

  @unboxed type init = Object(Dict.t<string>) | String(string) | Array(array<array<string>>)

  @new external make: unit => t = "URLSearchParams"
  @new external makeWithInit: init => t = "URLSearchParams"

  /** Appends a specified key/value pair as a new search parameter. */
  @send
  external append: (t, string, string) => unit = "append"

  /** Deletes the given search parameter, and its associated value, from the list of all search parameters. */
  @send
  external delete: (t, string) => unit = "delete"

  /** Returns the first value associated to the given search parameter. */
  @send
  @return(nullable)
  external get: (t, string) => option<string> = "get"

  /** Returns all the values association with a given search parameter. */
  @send
  external getAll: (t, string) => array<string> = "getAll"

  /** Returns a Boolean indicating if such a search parameter exists. */
  @send
  external has: (t, string) => bool = "has"

  /** Sets the value associated to a given search parameter to the given value. If there were several values, delete the others. */
  @send
  external set: (t, string, string) => unit = "set"

  /** Sorts all key/value pairs, if any, by their keys. */
  @send
  external sort: t => unit = "sort"

  /** Returns an iterator allowing to go through all entries of the key/value pairs. */
  @send
  external entries: t => Iterator.t<(string, string)> = "entries"

  /** Returns an iterator allowing to go through all keys of the key/value pairs of this search parameter. */
  @send
  external keys: t => Iterator.t<string> = "keys"

  /** Returns an iterator allowing to go through all values of the key/value pairs of this search parameter. */
  @send
  external values: t => Iterator.t<string> = "values"

  /** Executes a provided function once for each key/value pair. */
  @send
  external forEach: (t, (string, string, t) => unit) => unit = "forEach"

  /** Returns a string containing a query string suitable for use in a URL. Does not include the question mark. */
  @send
  external toString: t => string = "toString"
}

module Blob = {
  type t = Js.Blob.t

  /**
   * Create a new view **without 🚫 copying** the underlying data.
   *
   * Similar to [`BufferSource.subarray`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BufferSource/subarray)
   */
  @send
  external slice: (t, ~begin: float=?, ~end_: float=?, ~contentType: string=?) => t = "slice"

  /**
   * Read the data from the blob as a string. It will be decoded from UTF-8.
   */
  @send
  external text: t => promise<string> = "text"

  /**
   * Read the data from the blob as a ReadableStream.
   */
  @send
  external stream: (t, ~chunkSize: float=?) => ReadableStream.t = "stream"

  /**
   * Read the data from the blob as an ArrayBuffer.
   *
   * This copies the data into a new ArrayBuffer.
   */
  @send
  external arrayBuffer: t => promise<ArrayBuffer.t> = "arrayBuffer"

  /**
   * Read the data from the blob as a JSON object.
   *
   * This first decodes the data from UTF-8, then parses it as JSON.
   */
  @send
  external json: t => promise<Js.Json.t> = "json"

  /**
   * Read the data from the blob as a {@link FormData} object.
   *
   * This first decodes the data from UTF-8, then parses it as a
   * `multipart/form-data` body or a `application/x-www-form-urlencoded` body.
   *
   * The `type` property of the blob is used to determine the format of the
   * body.
   *
   * This is a non-standard addition to the `Blob` API, to make it conform more
   * closely to the `BodyMixin` API.
   */
  @send
  external formData: t => promise<FormData.t> = "formData"

  @get
  external getType: t => string = "type"

  @get
  external size: t => float = "size"
}

// https://github.com/oven-sh/bun/blob/main/packages/bun-types/globals.d.ts#L1331
module Request = {
  type t

  /**
   * The URL (as a string) corresponding to the HTTP request
   * @example
   * ```rescript
   * let request = Request.make("https://remix.run/")
   * request->Request.url; // "https://remix.run/"
   * ```
   */
  @get
  external url: t => string = "url"

  /**
   * Consume the [`Request`](https://developer.mozilla.org/en-US/docs/Web/API/Request) body as a string. It will be decoded from UTF-8.
   *
   * When the body is valid latin1, this operation is zero copy.
   */
  @send
  external text: t => promise<string> = "text"

  // TODO: body (readable stream)

  /**
   * Consume the [`Request`](https://developer.mozilla.org/en-US/docs/Web/API/Request) body as an ArrayBuffer.
   *
   */
  @send
  external arrayBuffer: t => promise<ArrayBuffer.t> = "arrayBuffer"

  /**
   * Consume the [`Request`](https://developer.mozilla.org/en-US/docs/Web/API/Request) body as a JSON object.
   *
   * This first decodes the data from UTF-8, then parses it as JSON.
   *
   */
  @send
  external json: t => promise<Js.Json.t> = "json"

  /**
   * Consume the [`Request`](https://developer.mozilla.org/en-US/docs/Web/API/Request) body as a `Blob`.
   *
   * This allows you to reuse the underlying data.
   *
   */
  @send
  external blob: t => promise<Blob.t> = "blob"

  /**
   * Read or write the HTTP headers for this request.
   *
   * @example
   * ```rescript
   * let request = Request.make("https://remix.run/");
   * request->Request.headers->Headers.set("Content-Type", "application/json");
   * request->Request.headers->Headers.set("Accept", "application/json");
   * let res = await fetch(request)
   * ```
   */
  @get
  external headers: t => Headers.t = "headers"
  @get external method: t => method = "method"
  @send external formData: t => promise<FormData.t> = "formData"
}

module TextEncoder = {
  type t
  @new external make: unit => t = "TextEncoder"
  @send external encode: (t, string) => Uint8Array.t = "encode"
}

module WritableStream = {
  type t

  module Writer = {
    type t

    @send external write: (t, Uint8Array.t) => unit = "write"
    @send external close: t => unit = "close"
  }

  @send external getWriter: t => Writer.t = "getWriter"
}

module TransformStream = {
  type t = {
    readable: ReadableStream.t,
    writable: WritableStream.t,
  }

  type chunk

  module Controller = {
    type t

    @send external enqueue: (t, chunk) => unit = "enqueue"
  }

  type config = {transform: (chunk, Controller.t) => unit}

  @new external make: config => t = "TransformStream"
}

module Response = {
  type t

  type baseResponseInit = {
    /** @default 200 */
    status?: int,
    /** @default "OK" */
    statusText?: string,
  }

  type responseInit = {
    ...baseResponseInit,
    headers?: HeadersInit.t,
  }

  type responseInitWithHeaders = {
    ...baseResponseInit,
    headers?: Headers.t,
  }

  type responseType =
    | @as("basic") Basic
    | @as("cors") Cors
    | @as("default") Default
    | @as("error") Error
    | @as("opaque") Opaque
    | @as("opaqueredirect") OpaqueRedirect

  external defer: t = "undefined"

  @new external make: (string, ~options: responseInit=?) => t = "Response"
  @new external makeFromFile: BunFile.t => t = "Response"
  @new external makeWithHeaders: (string, ~options: responseInitWithHeaders=?) => t = "Response"
  @new external makeFromFormData: (FormData.t, ~options: responseInit=?) => t = "Response"
  @new
  external makeFromURLSearchParams: (URLSearchParams.t, ~options: responseInit=?) => t = "Response"

  @new
  external makeFromReadableStream: (ReadableStream.t, ~options: responseInit=?) => t = "Response"

  /** Create a new Response that redirects to url */
  external makeRedirect: (string, ~status: int=?) => t = "Response.redirect"

  /** HTTP Headers sent with the response. */
  @get
  external headers: t => Headers.t = "headers"

  /** HTTP response body as a ReadableStream */
  @get
  @return(nullable)
  external body: t => option<ReadableStream.t> = "body"

  /** Has the body of the response already been consumed? */
  @get
  external bodyUsed: t => bool = "bodyUsed"

  /** Read the data from the Response as a string. It will be decoded from UTF-8. */
  @send
  external text: t => promise<string> = "text"

  /** Read the data from the Response as a string. It will be decoded from UTF-8. */
  @send
  external arrayBuffer: t => promise<ArrayBuffer.t> = "arrayBuffer"

  /** Read the data from the Response as a JSON object. */
  @send
  external json: t => promise<Js.Json.t> = "json"

  /** Read the data from the Response as a Blob. */
  @send
  external blob: t => promise<Blob.t> = "blob"

  /** Read the data from the Response as a FormData object. */
  @send
  external formData: t => promise<FormData.t> = "formData"

  @get external ok: t => bool = "ok"
  @get external redirected: t => bool = "redirected"

  /** HTTP status code */
  @get
  external status: t => int = "status"
  @get external statusText: t => string = "statusText"
  @get external type_: t => responseType = "type"
  @get external url: t => string = "url"

  /** Copy the Response object into a new Response, including the body */
  @send
  external clone: t => t = "clone"
}

type requestCache =
  | @as("default") Default
  | @as("force-cache") ForceCache
  | @as("no-cache") NoCache
  | @as("no-store") NoStore
  | @as("only-if-cached") OnlyIfCached
  | @as("reload") Reload

type requestCredentials =
  | @as("include") Include
  | @as("omit") Omit
  | @as("same-origin") SameOrigin

type requestDestination =
  | @as("") Empty
  | @as("audio") Audio
  | @as("audioworklet") AudioWorklet
  | @as("document") Document
  | @as("embed") Embed
  | @as("font") Font
  | @as("frame") Frame
  | @as("iframe") IFrame
  | @as("image") Image
  | @as("manifest") Manifest
  | @as("object") Object_
  | @as("paintworklet") PaintWorklet
  | @as("report") Report
  | @as("script") Script
  | @as("sharedworker") SharedWorker
  | @as("style") Style
  | @as("track") Track
  | @as("video") Video
  | @as("worker") Worker
  | @as("xslt") Xslt

type requestMode =
  | @as("cors") Cors
  | @as("navigate") Navigate
  | @as("no-cors") NoCors
  | @as("same-origin") SameOriginMode

type requestRedirect =
  | @as("error") Error
  | @as("follow") Follow
  | @as("manual") Manual

type referrerPolicy =
  | @as("") Empty
  | @as("no-referrer") NoReferrer
  | @as("no-referrer-when-downgrade") NoReferrerWhenDowngrade
  | @as("origin") Origin
  | @as("origin-when-cross-origin") OriginWhenCrossOrigin
  | @as("same-origin") SameOriginPolicy
  | @as("strict-origin") StrictOrigin
  | @as("strict-origin-when-cross-origin") StrictOriginWhenCrossOrigin
  | @as("unsafe-url") UnsafeUrl

type ipFamily = IPv4 | IPv6

type socketAddress = {
  /**
     * The IP address of the client.
     */
  address: string,
  /**
     * The port of the client.
     */
  port: int,
  /**
     * The IP family ("IPv4" or "IPv6").
     */
  family: ipFamily,
}

module WebSocket = {
  type t

  type config = {
    message?: (t, string) => unit,
    @as("open") open_?: t => unit,
    close?: (t, int, string) => unit,
    drain?: t => unit,
  }

  @send external send: (t, string) => unit = "send"

  /**
   * A status that represents the outcome of a sent message.
   *
   * - if **Dropped**, the message was **dropped**.
   * - if **-1**, there is **backpressure** of messages.
   * - if **>0**, it represents the **number of bytes sent**.
   *
   * @example
   * ```js
   * const status = ws.send("Hello!");
   * if (status === 0) {
   *   console.log("Message was dropped");
   * } else if (status === -1) {
   *   console.log("Backpressure was applied");
   * } else {
   *   console.log(`Success! Sent ${status} bytes`);
   * }
   * ```
   */
  @unboxed
  type serverWebSocketSendStatus =
    | @as(0.) Dropped
    | @as(-1.) Backpressure
    | SentBytes(float)

  @send
  external publish: (t, ~topic: string, ~data: string, ~compress: bool=?) => unit = "publish"

  @send
  external publishCheckStatus: (
    t,
    ~topic: string,
    ~data: string,
    ~compress: bool=?,
  ) => serverWebSocketSendStatus = "publish"

  @send
  external subscribe: (t, ~topic: string) => unit = "subscribe"

  @send
  external unsubscribe: (t, ~topic: string) => unit = "unsubscribe"
}

module Server = {
  type t

  /**
     * Stop listening to prevent new connections from being accepted.
     *
     * By default, it does not cancel in-flight requests or websockets. That means it may take some time before all network activity stops.
     *
     * @param closeActiveConnections Immediately terminate in-flight requests, websockets, and stop accepting new connections.
     * @default false
     */
  @send
  external stop: (t, ~closeActiveConnections: bool=?) => unit = "stop"

  /**
     * Update the `fetch` and `error` handlers without restarting the server.
     *
     * This is useful if you want to change the behavior of your server without
     * restarting it or for hot reloading.
     *
     * @example
     *
     * ```js
     * // create the server
     * const server = Bun.serve({
     *  fetch(request) {
     *    return new Response("Hello World v1")
     *  }
     * });
     *
     * // Update the server to return a different response
     * server.reload({
     *   fetch(request) {
     *     return new Response("Hello World v2")
     *   }
     * });
     * ```
     *
     * Passing other options such as `port` or `hostname` won't do anything.
     */
  type reloadServeOptions = {
    development?: bool,
    port?: int,
    fetch: (Request.t, t) => promise<Response.t>,
    websocket?: WebSocket.config,
  }

  @send
  external reload: (t, reloadServeOptions) => unit = "reload"

  @get external port: t => int = "port"
  @send external upgrade: (t, Request.t) => bool = "upgrade"

  @send
  external publish: (t, ~topic: string, ~data: string, ~compress: bool=?) => unit = "publish"

  @send
  external publishCheckStatus: (
    t,
    ~topic: string,
    ~data: string,
    ~compress: bool=?,
  ) => WebSocket.serverWebSocketSendStatus = "publish"

  /**
     * Returns the client IP address and port of the given Request. If the request was closed or is a unix socket, returns null.
     *
     * @example
     * ```js
     * export default {
     *  async fetch(request, server) {
     *    return new Response(server.requestIP(request));
     *  }
     * }
     * ```
     */
  @return(nullable)
  @send
  external requestIP: (t, Request.t) => option<socketAddress> = "requestIP"

  /**
     * How many requests are in-flight right now?
     */
  @get
  external pendingRequests: t => int = "pendingRequests"

  /**
     * How many {@link ServerWebSocket}s are in-flight right now?
     */
  @get
  external pendingWebSockets: t => int = "pendingWebSockets"

  /**
     * The hostname the server is listening on. Does not include the port
     * @example
     * ```js
     * "localhost"
     * ```
     */
  @get
  external hostname: t => string = "hostname"
  /**
     * Is the server running in development mode?
     *
     * In development mode, `Bun.serve()` returns rendered error messages with
     * stack traces instead of a generic 500 error. This makes debugging easier,
     * but development mode shouldn't be used in production or you will risk
     * leaking sensitive information.
     *
     */
  @get
  external development: t => bool = "development"

  /**
     * An identifier of the server instance
     *
     * When bun is started with the `--hot` flag, this ID is used to hot reload the server without interrupting pending requests or websockets.
     *
     * When bun is not started with the `--hot` flag, this ID is currently unused.
     */
  @get
  external id: t => string = "id"
}

type serveOptions = {
  development?: bool,
  port?: int,
  fetch: (Request.t, Server.t) => promise<Response.t>,
  websocket?: WebSocket.config,
}

external serve: serveOptions => Server.t = "Bun.serve"

/** The URL module represents an object providing static methods used for creating object URLs. */
module URL = {
  type t

  @new external make: string => t = "URL"

  @get external hash: t => string = "hash"
  @get external host: t => string = "host"
  @get external hostname: t => string = "hostname"
  @get external href: t => string = "href"

  /** Returns a USVString containing the whole URL. It is a synonym for URL.href. */
  @send
  external toString: t => string = "toString"

  @get external origin: t => string = "origin"
  @get external password: t => string = "password"
  @get external pathname: t => string = "pathname"
  @get external port: t => string = "port"
  @get external protocol: t => string = "protocol"
  @get external search: t => string = "search"

  @get external searchParams: t => URLSearchParams.t = "searchParams"

  @get external username: t => string = "username"

  /** Returns a USVString containing a serialized URL. It is mainly used by JavaScript engines for some internal purposes. */
  @send
  external toJSON: t => string = "toJSON"
}

module AsyncLocalStorage = {
  type t<'store>
  type context<'store>

  @module("node:async_hooks") @new external make: unit => t<_> = "AsyncLocalStorage"

  @send external run: (t<'store>, 'store, context<'store> => 'ret) => 'ret = "run"

  @send external getStore: t<'store> => 'store = "getStore"
}

module Fs = {
  type watchOptions = {recursive?: bool}

  type watchEventType =
    | @as("rename") Rename | @as("change") Change | @as("error") Error | @as("close") Close

  @module("fs")
  external watch: (string, ~options: watchOptions=?, (watchEventType, string) => unit) => unit =
    "watch"

  @module("node:fs/promises")
  external writeFile: (string, string) => promise<unit> = "writeFile"

  type mkdirOpts = {recursive?: bool}

  @module("node:fs/promises")
  external mkdir: (string, ~options: mkdirOpts=?) => promise<unit> = "mkdir"
}
