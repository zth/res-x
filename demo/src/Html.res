@jsx.component
let make = (~children) => {
  <html>
    <head>
      <link type_="text/css" rel="stylesheet" href={ResXAssets.assets.styles_css} />
    </head>
    <body className="bg-orange-200 p-10" hxBoost=true>
      {children}
      <ResX.Dev />
      <script src="https://unpkg.com/htmx.org@1.9.5" />
      <script type_="module" src={ResXAssets.assets.analytics_js} />
      <script type_="module" src={ResXAssets.assets.client__admin_ts} />
      <script type_="module" src={ResXAssets.assets.resXClient_js} async=true />
    </body>
  </html>
}
