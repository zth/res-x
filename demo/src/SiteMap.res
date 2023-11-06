@react.component
let make = () => {
  let context = HtmxHandler.useContext()

  context.requestController->ResX.RequestController.setDocHeader(
    Some(`<?xml version="1.0" encoding="UTF-8"?>`),
  )

  context.headers->Bun.Headers.set("Content-Type", "application/xml; charset=UTF-8")
  context.headers->Bun.Headers.set(
    "Cache-Control",
    ResX.Utils.CacheControl.make(~cacheability=Public, ~expiration=[MaxAge(Days(1.))]),
  )

  <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <url>
      <loc> {H.string("https://www.example.com/")} </loc>
      <lastmod> {H.string("2023-10-15")} </lastmod>
      <changefreq> {H.string("weekly")} </changefreq>
      <priority> {H.string("1.0")} </priority>
    </url>
  </urlset>
}

Console.log(ResX.Utils.CacheControl.make(~cacheability=Public, ~expiration=[MaxAge(Days(1.))]))
