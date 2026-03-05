@@jsxConfig({module_: "Hjsx"})

@jsx.component
let make = () =>
  <html>
    <head>
      <link rel="stylesheet" href={ResXAssets.assets.styles_css} />
      <script src={ResXAssets.assets.resXClient_js} async=true />
    </head>
    <body>
      <h1>{Hjsx.string("bun-assets-smoke")}</h1>
    </body>
  </html>
