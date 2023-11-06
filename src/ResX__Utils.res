module CacheControl = {
  type t = string

  type time =
    | Seconds(float)
    | Minutes(float)
    | Hours(float)
    | Days(float)
    | Weeks(float)
    | Months(float)
    | Years(float)

  let rec timeToString = (t: time) =>
    switch t {
    | Seconds(seconds) => seconds->Float.toString
    | Minutes(minutes) => timeToString(Seconds(60. *. minutes))
    | Hours(hours) => timeToString(Minutes(60. *. hours))
    | Days(days) => timeToString(Hours(24. *. days))
    | Weeks(weeks) => timeToString(Days(7. *. weeks))
    | Months(months) => timeToString(Days(30. *. months))
    | Years(years) => timeToString(Days(365. *. years))
    }

  type cacheability =
    | /** This is for the directive "public". Indicates the response may be cached by any cache. */
    @as("public")
    Public
    | /** This is for the directive "private". The response is for a specific user and must not be stored by shared caches. */
    @as("private")
    Private
    | /** This is for the directive "no-store". Absolutely forbids storing the resource in cache. */
    @as("no-store")
    NoStore

  let cacheabilityToString = (c: cacheability) => (c :> string)

  @tag("kind")
  type expiration =
    | /** This is for the directive "max-age". Defines how long the resource is considered fresh. */
    @as("max-age")
    MaxAge(time)
    | /** This is for the directive "s-maxage". Applies only to shared caches. Defines how long the resource is considered fresh. */
    @as("s-maxage")
    SharedCacheMaxAge(time)
    | /** This is for the directive "max-stale". Accepts a stale response up to the specified age. */
    @as("max-stale")
    MaxStale(time)
    | /** This is for the directive "min-fresh". The client wants a response that will remain fresh for at least the specified time. */
    @as("min-fresh")
    MinFresh(time)

  let expirationToString = (e: expiration) =>
    switch e {
    | MaxAge(time) => `max-age=${time->timeToString}`
    | SharedCacheMaxAge(time) => `s-maxage=${time->timeToString}`
    | MaxStale(time) => `max-stale=${time->timeToString}`
    | MinFresh(time) => `min-fresh=${time->timeToString}`
    }

  @tag("kind")
  type revalidation =
    | /** This is for the directive "must-revalidate". Cache must revalidate once a resource becomes stale. */
    @as("must-revalidate")
    MustRevalidate
    | /** This is for the directive "proxy-revalidate". Same as must-revalidate, but for shared caches. */
    @as("proxy-revalidate")
    ProxyRevalidate
    | /** This is for the directive "stale-while-revalidate". Indicates that the client accepts a stale response while the cache fetches a fresh one. */
    @as("stale-while-revalidate")
    StaleWhileRevalidate(time)
    | /** This is for the directive "stale-if-error". Uses the stale response if revalidation fails. */
    @as("stale-if-error")
    StaleIfError(time)

  let revalidationToString = (r: revalidation) =>
    switch r {
    | MustRevalidate => "must-revalidate"
    | ProxyRevalidate => "proxy-revalidate"
    | StaleWhileRevalidate(time) => `stale-while-revalidate=${time->timeToString}`
    | StaleIfError(time) => `stale-if-error=${time->timeToString}`
    }

  type modifiers =
    | /** This is for the directive "no-transform". Caches shouldn't modify the response. */
    @as("no-transform")
    NoTransform
    | /** This is for the directive "immutable". The response will not change over time. */
    @as("immutable")
    Immutable
    | /** This is for the directive "only-if-cached". Wants only a cached response. */
    @as("only-if-cached")
    OnlyIfCached

  let modifiersToString = (m: modifiers) => (m :> string)

  @tag("kind")
  type extensions =
    | /** This is for the directive "must-understand". Caches that don't recognize this directive should treat the entire Cache-Control as invalid. */
    @as("must-understand")
    MustUnderstand
    | /** This is for the directive "no-store-remote". Shared caches shouldn't store the response, but private caches can. */
    @as("no-store-remote")
    NoStoreRemote
    | /** This is for the directive "wait-while-invalidate". Time a client waits for a cache to validate an entry with the origin server. */
    @as("wait-while-invalidate")
    WaitWhileInvalidate(time)

  let extensionsToString = (e: extensions) =>
    switch e {
    | MustUnderstand => "must-understand"
    | NoStoreRemote => "no-store-remote"
    | WaitWhileInvalidate(time) => `wait-while-invalidate=${time->timeToString}`
    }

  let make = (
    ~noCache=false,
    ~cacheability=?,
    ~expiration=?,
    ~revalidation=?,
    ~modifiers=?,
    ~extensions=?,
  ) => {
    [
      cacheability->Option.map(cacheabilityToString),
      if noCache {
        Some("no-cache")
      } else {
        None
      },
      expiration->Option.map(e => e->Array.map(expirationToString)->Array.joinWith(", ")),
      revalidation->Option.map(r => r->Array.map(revalidationToString)->Array.joinWith(", ")),
      modifiers->Option.map(r => r->Array.map(modifiersToString)->Array.joinWith(", ")),
      extensions->Option.map(r => r->Array.map(extensionsToString)->Array.joinWith(", ")),
    ]
    ->Array.keepSome
    ->Array.joinWith(", ")
  }

  module Presets = {
    /** Static assets like stylesheets, images, or scripts with extended caching. */
    let staticAssetsLongCache = make(
      ~cacheability=Public,
      ~expiration=[MaxAge(Years(1.))],
      ~modifiers=[Immutable],
    )

    /** Dynamic content like news feeds with short caching. */
    let frequentlyChangingContent = make(~cacheability=Public, ~expiration=[MaxAge(Minutes(5.))]) // 5 minutes

    /** Sensitive or user-specific content with no shared caching. */
    let sensitiveContent = make(
      ~cacheability=Private,
      ~expiration=[MaxAge(Seconds(0.))], // Immediate expiration
      ~revalidation=[MustRevalidate],
    )

    /** Dynamic content that's cached but frequently revalidated. */
    let alwaysValidate = make(
      ~cacheability=Public,
      ~expiration=[MaxAge(Minutes(1.))],
      ~revalidation=[MustRevalidate],
    )

    /** Content that should never be cached. */
    let neverCache = make(~noCache=true, ~cacheability=NoStore)
  }
}
