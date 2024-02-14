@jsx.component
let make = () => {
  let context = HtmxHandler.useContext()

  context.requestController->ResX.RequestController.setDocHeader(
    Some(`<?xml version="1.0" encoding="UTF-8"?>`),
  )

  context.headers->Headers.set("Content-Type", "application/xml; charset=UTF-8")
  context.headers->Headers.set(
    "Cache-Control",
    ResX.Utils.CacheControl.make(~cacheability=Public, ~expiration=[MaxAge(Days(1.))]),
  )

  <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <url>
      <loc> {Hjsx.string("https://www.example.com/")} </loc>
      <lastmod> {Hjsx.string("2023-10-15")} </lastmod>
      <changefreq> {Hjsx.string("weekly")} </changefreq>
      <priority> {Hjsx.string("1.0")} </priority>
    </url>
  </urlset>
}
