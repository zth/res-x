# ResX

A ReScript framework for building server-driven web sites and applications. Use familiar tech like JSX and the component model from React, combined with simple server driven client side technologies like HTMX. Built on Bun and Vite.

ResX is suitable for building everything from blogs to complex web applications.

## Philosophy

ResX focuses on the web platform, and aims to see how far we can get building web sites and applications before reaching for a full blown client side framework is necessary.

ResX has an "open hood". That means that it's trying to stay close to the metal, and have fairly few abstractions. It encourages you to understand how a web server and the web platform works. This will lead to you building better and more robust things as you're encouraged to understand the platform itself.

## Demo

_The demo is currently a WIP._
The `demo/` will contain a comprehensive example of using ResX.

## Getting started

First, make sure you have [`Bun`](https://bun.sh) installed and setup. Then, install `rescript-x` and the dependencies needed:

```bash
npm i rescript-x vite @rescript/core rescript-bun
```

Note that ResX requires these versions:

- `rescript@>=11.1.0-rc.2`
- `@rescript/core@>=1.0.0`
- `rescript-bun@>=0.4.1`

Configure our `rescript.json`:

```json
{
  "jsx": {
    "module": "Hjsx"
  },
  "bs-dependencies": ["@rescript/core", "rescript-x", "rescript-bun"],
  "bsc-flags": [
    "-open RescriptCore",
    "-open RescriptBun",
    "-open RescriptBun.Globals",
    "-open ResX.Globals"
  ]
}
```

Go ahead and install the dependencies for Tailwind as well if you want to use it:

```bash
npm i autoprefixer postcss tailwindcss
```

Let's set everything up. Start by setting up `vite.config.js`:

```javascript
import { defineConfig } from "vite";
import { resXVitePlugin } from "rescript-x";

export default defineConfig({
  plugins: [resXVitePlugin()],
  server: {
    port: 9000,
  },
});
```

Make sure you have both folders for static assets set up: `assets` and `public` in the root, next to `vite.config.js`. More on static assets later.

If you're using Tailwind, add `tailwind.config.js` and `postcss.config.js` as well:

```javascript
// postcss.config.js
module.exports = {
  plugins: [require("tailwindcss"), require("autoprefixer")],
};
```

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.res"],
  theme: {
    extend: {},
  },
  plugins: [],
};
```

There! If you want, you can also set up a bunch of scripts in `package.json` that'll make life easier:

```json
{
  "scripts": {
    "start": "NODE_ENV=production bun run src/App.js",
    "build": "NODE_ENV=production && bun run build:vite && bun run build:res",
    "build:vite": "vite build",
    "build:res": "rescript",
    "clean:res": "rescript clean",
    "dev:res": "rescript build -w",
    "dev:server": "bun --watch run src/App.js",
    "dev:vite": "vite",
    "dev": "concurrently 'bun:dev:*'"
  }
}
```

> Note: These scripts use `concurrently`. Install via `npm i concurrently`.

Now, let's create your `Handler` instance. You'll use this throughout your app as a sort of context:

```rescript
// Handler.res

// This context will be passed throughout your application. Use it for any per-request needs, like dataloaders, the id of the currently logged in user, etc.
type context = {userId: option<string>}

// `requestToContext` should produce your context above from the pending `request`. It'll be called fresh for each request.
let handler = ResX.Handlers.make(~requestToContext=async _request => {
  userId: None,
})

// This isn't required but is a shorthand to pull out the context a bit more conveniently from your handler.
let useContext = () => ResX.Handlers.useContext(handler)
```

Next, let's set up our webserver via Bun:

```rescript
// App.res
let port = 4444

let server = Bun.serve({
  port,
  development: ResX.BunUtils.isDev,
  fetch: async (request, server) => {
    open Bun

    // Serve static files first
    switch await ResX.BunUtils.serveStaticFile(request) {
    | Some(staticResponse) => staticResponse
    | None =>
      // Handle the request using the ResX handler if this wasn't a static file request.
      // Note: By default, all HTMX handler routes are prefixed with "_api", and all form action routes are prefixed with "_form".
      await Handler.handler->ResX.Handlers.handleRequest({
        request,
        setupHeaders: () => {
          // You can do any basic headers setup here that you want. These can be overwritten easily by your main application regardless of what you set here.
          Headers.makeWithInit(FromArray([("Content-Type", "text/html")]))
        },
        render: async ({path, requestController, headers}) => {
          // This handles the actual request.
          switch path {
          | list{"sitemap.xml"} => <SiteMap />
          | appRoutes =>
            requestController->ResX.RequestController.appendTitleSegment("Test App")
            <Html>
              <div>
                {switch appRoutes {
                | list{} =>
                  <div> {Hjsx.string("Start page!")} </div>
                | list{"moved"} =>
                  requestController->ResX.RequestController.redirect("/start", ~status=302)
                | _ =>
                  requestController->ResX.RequestController.setStatus(404)
                  <div>{Hjsx.string("404")}</div>
                }}
              </div>
            </Html>
          }
        },
      })
    }
  },
})

let portString = server->Bun.Server.port->Int.toString

Console.log(`Listening! on localhost:${portString}`)

// Run the dev server, responsible for hot module reloading etc, when in dev mode.
if ResX.BunUtils.isDev {
  ResX.BunUtils.runDevServer(~port)
}
```

Note that there's plenty of more things you can configure here, but for the sake of keeping it simple we'll just go with the basics.

You can now start up the dev environment: `bun run dev`. Open up `localhost:9000` and you should see your "Start page!" string.

There's a ton more to ResX of course, but this should get you started.

### Routing

As you noticed from the example above, there's no explicit router in ResX itself. In the future, we might ship a dedicated type safe router in the style of [rescript-relay-router](https://github.com/zth/rescript-relay-router). But for now, we'll use pattern matching!

You route by just pattern matching on `path`:

```rescript
switch path {
| list{} =>
  // Path: /
  <div> {Hjsx.string("Start page!")} </div>
| list{"moved"} =>
  // Path: /moved
  requestController->ResX.RequestController.redirect("/start", ~status=302)
| _ =>
  // Any other path
  requestController->ResX.RequestController.setStatus(404)
  <div>{Hjsx.string("404")}</div>
}
```

## Static assets

ResX comes with full static asset (fonts, images, etc) handling via Vite, that you can use if you want. In order to actually serve the static assets, make sure you use `ResX.BunUtils.serveStaticFile` before trying to handle your request in another way:

```rescript
fetch: async (request, server) => {
    open Bun

    switch await ResX.BunUtils.serveStaticFile(request) {
    | Some(staticResponse) => staticResponse
    | None =>
      await Handler.handler->ResX.Handlers.handleRequest({
        ...
```

`ResX.BunUtils.serveStaticFile` check if the request is for a static file, and if it is return a response serving that static file via `Bun`. If it's not a static file request, you continue as usual with serving the response.

As for the assets themselves, there are two ways of handling them in ResX:

### `public` for assets that don't need transformation

Putting assets in the `public` directory. Any assets you put in the top level `public` directory next to `vite.config.js` will be copied as-is to your production environment. It's then available to you via the top level:

```
// public/robots.txt exists
GET /robots.txt
```

### `assets` for assets that do need transformation

If you have assets you'd like transformed by Vite before using, put them in the top level `assets` folder. This could be CSS, images, additional JavaScript, and so on. Anything you might want Vite to transform.

Here's an example of how you wire up Tailwind:

```css
/* assets/styles.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Then, include it in your ReScript:

```rescript
<head>
  <link type_="text/css" rel="stylesheet" href={ResXAssets.assets.styles_css} />
</head>
```

There! It's now available to you, and Vite will both transform and hot module reload the asset if it's possible.

#### Referring to transformed `assets`

Notice how we're not using a `"/assets/styles.css"` string to refer to `styles.css`, but rather `ResXAssets.assets.styles_css`? This is because ResX comes with a "type safe" asset layer - anything you put in `assets/` will be available via `ResXAssets.assets`.

**Always use this to refer to assets**. One for the type safety of course, but also because this is how Vite keeps track of all asset files, so you get the transformed asset in production, and so on.

> Bonus: Since the asset map is a regular ReScript record, you'll automatically get dead code analysis via the ReScript code analyzer. Dead code analysis for your assets! Makes it really easy to keep your assets folder clean.

## ResX client side tools

ResX wants you to think "server side rendering" as much as possible. In order to allow you to take this as far as possible, ResX ships with 2 client side libraries that's intended to help you solve as many cases where client side JavaScript is needed as possible.

### HTMX

ResX comes pre-baked with full HTMX support.

Make sure you include the HTMX script:

```rescript
<script src="https://unpkg.com/htmx.org@1.9.5" />
```

#### hx-get, hx-post and friends

ResX has first class support for using `hx-get`, `hx-post` and friends from HTMX. There are two ways to use each `hx` attribute:

1. Via the builtin ResX HTML attribute `hx<method>`. So, for example `hxGet`. This is the recommended way. Details below on how to use this.
2. Putting a raw string on the `hx<method>` attribute. This is useful when you want to use HTMX with a route URL that you don't want to go through the regular ResX handling. Every `hx<method>` comes with an equivalent `rawHx<method>` prop, that takes a plain string. So you could do this: `rawHxGet={"/some/path"}`.

In the vast majority of cases you'll likely use number 1. In order to use 1., you create a `htmxHandler`, and then attach actions to that handler. You then pass those actions to `hxGet`, `hxPost` etc. Here's a simple example.

First, set up your `htmxHandler`. This maker takes a `requestToContext` function, that's responsible for translating a request into a (per-request) context. This is where you put the current user ID, dataloaders, or whatever else you want to have available through the lifetime of your request.

```rescript
// Handler.res
type context = {userId: option<string>}

let handler = ResX.Handlers.make(~requestToContext=async request => {
  // Pull out the current user ID from the request, if it exists
  userId: Some("some-user-id"),
})

// Short hand for retrieving the context
let useContext = () => handler->ResX.Handlers.useContext
```

Now, we can attach and use actions via this handler:

```rescript
// User.res
let onForm = Handler.handler->ResX.Handlers.hxPost("/user-single", ~securityPolicy=ResX.SecurityPolicy.allow, ~handler=async ({request}) => {
  let formData = await request->Request.formData
  try {
    let name = formData->ResX.FormDataHelpers.expectString("name")
    <div>{Hjsx.string(`Hi ${name}!`)}</div>
  } catch {
  | Exn.Error(err) =>
    Console.error(err)
    <div> {Hjsx.string("Failed...")} </div>
  }
})

@jsx.component
let make = () => {
  <form
    hxPost={onForm}
    hxSwap={ResX.Htmx.Swap.make(InnerHTML)}
    hxTarget={ResX.Htmx.Target.make(CssSelector("#user-single"))}>
    <input type_="text" name="name" />
    <div id="user-single">
      {Hjsx.string("Hello...")}
    </div>
    <button>{Hjsx.string("Submit")}</button>
  </form>
}
```

This is all wired up automatically via `ResX.Handlers.handleRequest`. Also notice that as all of this is server side, you don't need to worry about accidentally leaking things to the client.

##### Handling cyclic dependencies

Sometimes you end up in a situation where you want to refer to the `hxGet` (or any other `hx` handler) you're implementing inside of the implementation itself. For example, a component that can "refresh" itself. This can't be done with the regular `ResX.Handlers.get` etc because that'd create a situation of cyclic dependencies where the definition of the handler refers to itself. In order to handle these specific scenarios, you can leverage `ResX.Handlers.makeGet` + `ResX.Handlers.implementGet` to first get a `hxGet` identifier you can attach to your DOM nodes, and _then_ implement it in a place where you won't get cyclic dependencies.

Let's look at the example above and adjust it to work that way instead:

```rescript
// User.res
let onForm = Handler.handler->ResX.Handlers.makeHxPostIdentifier("/user-single")

Handler.handler->ResX.Handlers.implementHxPostIdentifier(onForm, ~securityPolicy=ResX.SecurityPolicy.allow, ~handler=async ({request}) => {
  let formData = await request->Request.formData
  try {
    let name = formData->ResX.FormDataHelpers.expectString("name")
    <div>{Hjsx.string(`Hi ${name}!`)}</div>
  } catch {
  | Exn.Error(err) =>
    Console.error(err)
    <div> {Hjsx.string("Failed...")} </div>
  }
})

@jsx.component
let make = () => {
  <form
    hxPost={onForm}
    hxSwap={ResX.Htmx.Swap.make(InnerHTML)}
    hxTarget={ResX.Htmx.Target.make(CssSelector("#user-single"))}>
    <input type_="text" name="name" />
    <div id="user-single">
      {Hjsx.string("Hello...")}
    </div>
    <button>{Hjsx.string("Submit")}</button>
  </form>
}
```

Notice how producing the `hxPost` identitifer is now separate from implementing it. This means you can put the implementation in a place where it won't suffer from circular dependencies.

#### Other hx-attributes are handled type safely

> Note: All `hx`-attributes have equivalent `raw` versions, so you can always opt out of the type safe handling if it doesn't suite your needs.

All `hx`-attributes have type safe maker-style APIs. Let's look at the example above again:

```rescript
@jsx.component
let make = () => {
  <form
    hxPost={onForm}
    hxSwap={ResX.Htmx.Swap.make(InnerHTML)}
    hxTarget={ResX.Htmx.Target.make(CssSelector("#user-single"))}>
    <input type_="text" name="name" />
    <div id="user-single">
      {Hjsx.string("Hello...")}
    </div>
    <button>{Hjsx.string("Submit")}</button>
  </form>
}
```

Notice how `hxSwap` and `hxTarget` are passed things from `Htmx.Something.make`? This is the way you interface with the typed `hx` attributes.

### Security policies

All HTMX handlers and form actions require a `securityPolicy` parameter. This allows you to control access to your endpoints by evaluating each request before the handler is executed, and forces you to consider security for each endpoint you expose.

A security policy is a function that takes the request and context, and returns either `Allow` or `Block` with optional error details:

```rescript
// Allow all requests
~securityPolicy=ResX.SecurityPolicy.allow

// Custom security policy
~securityPolicy=async ({request, context}) => {
  switch context.userId {
  | Some(_userId) => ResX.SecurityPolicy.Allow
  | None => ResX.SecurityPolicy.Block({
      code: Some(401),
      message: Some("Authentication required"),
    })
  }
}
```

When a request is blocked by a security policy, a response is returned with (optionally) the status code and message provided by the security policy function.

### Regular form actions

Sometimes you don't need a full blown HTMX handler for handling a form action. Maybe all you want to do is redirect, or something else where you want full control over what response you return.

This is easy to do in `ResX` using a `formAction`. It's similar to a HTMX handler. Let's look at how to implement a form action that redirects as a form is submitted:

```rescript
// User.res
let onSubmit = Handler.handler->ResX.Handlers.formAction("/some-url", ~securityPolicy=ResX.SecurityPolicy.allow, ~handler=async ({request, context}) => {
  Response.makeRedirect("/some-other-page")
})

@jsx.component
let make = () => {
  <form action={onSubmit}>
    <button>{Hjsx.string("Submit and get redirected!")}</button>
  </form>
}
```

Form actions have access to your `context` object, as well as the full `request` object. They're expected to return a `Response.t`, which you're in charge of building yourself.

You control whether you want the form method to be `POST` or `GET` via the `method` attribute on `<form>`, just like you normally do.

### ResX Client

ResX also ships with a tiny client side library that will help you do basic client side tasks fully declaratively. It's quite basic at the moment, but will be extended (tastefully) as we discover more places where it can help you avoid having to use a full blown client side framework to accomplish fairly basic tasks.

To use ResX client, make sure you include its script:

```rescript
<script src={ResXAssets.assets.resXClient_js} async=true />
```

#### Handling CSS classes on events

Sometimes all you need to do is add, remove or toggle a CSS class in response to something like a click somewhere. Here's how you do that with ResX:

```rescript
<button
  id="test"
  resXOnClick={ResX.Client.Actions.make([
    ToggleClass({className: "text-xl", target: This}),
  ])}>
  {Hjsx.string("Submit form")}
</button>
```

Notice `resXOnClick`. This will trigger on any click of the button, and toggle the CSS class `text-xl` on the `button` element itself.

Have a look in the `ResX.Client` module for an exhaustive list of all actions that are available and how to use them.

#### Setting custom validity messages for HTML5 form validation

Contrary to popular belief, the [built in HTML5 form validation](https://developer.mozilla.org/en-US/docs/Learn/Forms/Form_validation#using_built-in_form_validation) is actually pretty good, and will get you really far before you need to reach for client side JavaScript to validate. But, it has one glaring omission that makes it harder - you can't set custom validation messages without a fairly involved process, depending on client side JavaScript. ResX aims to fix this via `resXValidityMessage`:

```rescript
<input
  type_="text"
  name="lastName"
  required=true
  resXValidityMessage={ResX.Client.ValidityMessage.make({
    valueMissing: "Yo, you need to fill this in!",
  })}
/>
```

This will turn the validity message for when the value is missing (since it's marked a `required`) into the supplied message, rather than the generic message printed by the browser.

`resXValidityMessage` supports changing all available validity messages. Refer to the `ResX.Client.ValidityMessage` module for an exhaustive list.

## Building UI with ResX

If you're familiar with React, JSX and the component model, building UI with ResX is very straight forward. It's essentially like using React as a templating engine, with a sprinkle of React Server Components flavor.

In ResX, you'll interface with 2 modules mainly when working with JSX:

1. `Hjsx` - this holds functions like `string`, `int` etc for converting primitives to JSX, and a bunch of things that are needed for the JSX transform.
2. `H` - this holds the `Context` module, as well as functions for turning JSX elements into strings.

The bulk of your code is going to be (reusable) components. You define one just like you do in React, with the difference that `React.string`, `React.int` etc are called `Hjsx.string` and `Hjsx.int`, and `@react.component` is called `@jsx.component` instead:

```rescript
// Greet.res
@jsx.component
let make = (~name) => {
  <div>{Hjsx.string("Hello " ++ name)}</div>
}

// SomeFile.res
@jsx.component
let make = (~userName) => {
  <div>
    <Greet name=userName />
  </div>
}
```

### Rendering unescaped content

By default, all content in ResX is properly HTML-escaped for security. However, there are legitimate cases where you need to output raw content (like content from a CMS, CSV files or similar "non HTML content", markdown processors, or trusted HTML strings). For these cases, ResX provides `Hjsx.dangerouslyOutputUnescapedContent`:

```rescript
@jsx.component
let make = (~trustedHtmlContent) => {
  <div>
    {Hjsx.string("This content is escaped: <script>alert('xss')</script>")}
    {Hjsx.dangerouslyOutputUnescapedContent(trustedHtmlContent)}
  </div>
}
```

**CRITICAL SECURITY WARNING**: `dangerouslyOutputUnescapedContent` completely bypasses HTML escaping. Never use this function with user-provided content or any untrusted data, as it can create XSS vulnerabilities. Only use this with content you trust completely, such as:

- Static HTML strings in your code
- Content from trusted CMS systems that handle their own sanitization
- Pre-sanitized content from trusted markdown processors
- Generated HTML from your own trusted systems
- **Raw non-HTML content** like CSV data, or other structured data formats (see the [CSV export](#csv-export-example) example in the Doc header section)

When outputting non-HTML content types (CSV, XML, etc.), you'll typically need to:

1. Set the appropriate `Content-Type` header
2. Remove or customize the doc header using `setDocHeader`
3. Use `dangerouslyOutputUnescapedContent` to output the raw content without HTML escaping

When in doubt, use `Hjsx.string` instead, which safely escapes all content.

### Async components

Components can be defined using `async`/`await`. This enables you to do data fetching directly in them:

```rescript
// User.res
@jsx.component
let make = async (~id) => {
  let user = await getUser(id)

  <div>{Hjsx.string("Hello " ++ user.name)}</div>
}
```

> WARNING! As with all async things you need to be careful to not create waterfalls, or performance will suffer. Handling that is out of scope for this readme, but following this tip will get you far - _initiate data fetching_ as far up the tree as possible. Awaiting the data is fine to do in leaf components, but it's good for perf to initiate data fetching as high up as possible, and then pass the promise of that data down the tree.

### Context

Just like in React, you can use context to pass data down your tree without having to prop drill it:

```rescript
// CurrentUserContext.res
let context = H.Context.createContext(None)

let use = () => H.Context.useContext(context)

module Provider = {
  let make = H.Context.provider(context)
}

@jsx.component
let make = (~children, ~currentUserId: option<string>) => {
  <Provider value={currentUserId}> {children} </Provider>
}

// App.res
let currentUserId = request->UserUtils.getCurrentUserId
<CurrentUserContext currentUserId>
  <div> ... </div>
</CurrentUserContext>

// LoggedInUser.res
// This is rendered somewhere far down in the tree
@jsx.component
let make = () => {
  switch CurrentUserId.use() {
  | None => <div>{Hjsx.string("Not logged in")}</div>
  | Some(currentUserId) => <div>{Hjsx.string("Logged in as: " ++ currentUserId)}</div>
  }
}
```

### Error boundaries

Just like in React, you can protect parts of your UI from errors during render using an error boundary, using the `<ResX.ErrorBoundary />` component. You need to pass it a `renderError` function, and this function will be called whenever there's an error:

```rescript
<ResX.ErrorBoundary renderError={err => {
  Console.error(err)
  <div>{Hjsx.string("Oops, this blew up!")}</div>
}}>
  <div>
    <ComponentThatWillBlowUp />
  </div>
</ResX.ErrorBoundary>
```

You can use as many error boundaries as you want. You're recommended to wrap your entire app with an error boundary as well.

## Request conveniences

ResX ships with a number of conveniences for handling common things when building responses for requests.

### `onBeforeBuildResponse` hook for manipulating the context before the response is built

`onBeforeBuildResponse` lets you manipulate your request specific context before ResX starts generating HTML. Let's look at an example of adding a script tag to the head if a certain criteria has been met:

```rescript
await Handler.handler->ResX.Handlers.handleRequest({
  request,
  onBeforeBuildResponse: ({context, request}) => {
    // Imagine `shouldLoadHtmx` can be set to true by the code that has executed for this particular route. A component could for example mark itself as needing HTMX.
    if context.shouldLoadHtmx {
      response->ResX.RequestController.appendToHead(<script src="https://unpkg.com/htmx.org@1.9.5" async=true />)
    }
  },
  render: async ({path, requestController, headers}) => {
    // This handles the actual request.
    ...
```

### `onBeforeSendResponse` hook for manipulating the final response before sending it

`onBeforeSendResponse` lets you manipulate the response you're producing one last time before sending it to the client. Let's look at an example of overriding any cache header set when the user is logged in:

```rescript
await Handler.handler->ResX.Handlers.handleRequest({
  request,
  onBeforeSendResponse: ({context, response, request}) => {
    // Change (or replace) the final response here.
    if context.isLoggedIn {
      response->Response.headers->Headers.set("Cache-Control", "no-store, no-cache"))
    }

    response
  },
  render: async ({path, requestController, headers}) => {
    // This handles the actual request.
    ...
```

This way, you can conveniently make sure that no logged in pages are cached, and so on.

### `<title>` integration

It's nice to be able to set the `<title>` incrementally as you render your app. But, `<title>` belongs in `<head>` and when you render `<head>` you probably don't have everything you need to produce the title you want.

Therefore, ResX ships with a helper for handling the title using `ResX.RequestController`. This helper lets you either _append_ items to the title, or _set the full title_. You can then easily build your title element as you render your app, without having to know the full title as you render `<head>`:

```rescript
// App.res
let context = ResX.Handlers.useContext(HtmxHandler.handler)
context.requestController->ResX.RequestController.prependTitleSegment("My App")

// Users.res
// Title is now "Users | MyApp"
context.requestController->ResX.RequestController.prependTitleSegment("Users")

// SingleUser.res
// Title is now "Someuser Name | Users | MyApp"
context.requestController->ResX.RequestController.prepentTitleSegment(user.name)

// There's also an `appendTitleSegment` for appending to the title
// Title is now "Someuser Name | Users | MyApp | Appeneded Content"
context.requestController->ResX.RequestController.appendTitleSegment("Appeneded Content")

```

It's also easy to set the title to something else entirely with `setFullTitle`:

```rescript
// SingleUser.res
// Title is now "Failed!"
context.requestController->ResX.RequestController.setFullTitle("Failed!")
```

> Note: You control how the title is rendered by passing a `renderTitle` function to `handleRequest`.

### Generic append to head

It's not just `<title>` that might be inconvenient to have to produce as you're rendering `<head>`. You might have styles or other things that you might want to load depending on what you're rendering, and that belongs in `<head>`. `ResX.RequestController` comes with a generic `appendToHead` function for that:

```rescript
// SingleUser.res
context.requestController->ResX.RequestController.appendToHead(<link href={ResXAssets.assets.single_user_page_styles_css} rel="text/stylesheet" />)
```

There's also a component you can use to render things into head. This component can be rendered anywhere in the component tree and the content will still be rendered in `<head>`:

```rescript
// SingleUser.res
<div>
  <ResX.RenderInHead>
    <link href={ResXAssets.assets.single_user_page_styles_css} rel="text/stylesheet" />
  </ResX.RenderInHead>
</div>
```

### Redirects

You can redirect easily using `ResX.RequestController.redirect`:

```rescript
requestController->ResX.RequestController.redirect("/start", ~status=302)
```

This returns a JSX element, so you can easily integrate it wherever you want to set the redirect:

```rescript
switch path {
| list{"moved"} =>
  requestController->ResX.RequestController.redirect("/start", ~status=302)
```

### Cache control

Cache headers can be a bit confusing. ResX comes with a helper to produce the cache control header string via `ResX.Utils.CacheControl`. Here's an example:

```rescript
// Sets Cache-Control to "public, max-age=86400"
context.headers->Headers.set(
  "Cache-Control",
  ResX.Utils.CacheControl.make(~cacheability=Public, ~expiration=[MaxAge(Days(1.))]),
)
```

There's also a number of cache control presets available under `ResX.Utils.CacheControl.Presets`. This includes examples for static assets that are to be cached long term, to sensitive content that should never be cached by anyone.

### Response status

You can set the response status anywhere when rendering:

```rescript
// FourOhFour.res
@jsx.component
let make = () => {
  let context = ResX.Handlers.useContext(HtmxHandler.handler)
  context.requestController->ResX.RequestController.setStatus(404)

  <div> {Hjsx.string("404")} </div>
}
```

### Other headers

Setting any other header anywhere when rendering is also easy:

```rescript
let context = ResX.Handlers.useContext(HtmxHandler.handler)
context.headers->Headers.set("Content-Type", "text/html")
```

### Advanced: Doc header

By default, any returned content from your handlers is prefixed with `<!DOCTYPE html>` because you're expected to return HTML. However, there are cases where you might want to return other things than HTML but still use JSX. Examples include returning XML to produce a site map, CSV files for data export, or other structured data formats. For that, you can leverage `ResX.RequestController.setDocHeader`:

#### XML sitemap example

```rescript
// SiteMap.res
@jsx.component
let make = () => {
  let {requestController, headers} = HtmxHandler.handler->ResX.Handlers.useContext

  requestController->ResX.RequestController.setDocHeader(
    Some(`<?xml version="1.0" encoding="UTF-8"?>`),
  )

  headers->Headers.set("Content-Type", "application/xml; charset=UTF-8")
  headers->Headers.set(
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
```

#### CSV export example

```rescript
// UserCsvExport.res
@jsx.component
let make = async (~users: array<user>) => {
  let {requestController, headers} = HtmxHandler.handler->ResX.Handlers.useContext

  // Remove the HTML doctype since we're returning CSV
  requestController->ResX.RequestController.setDocHeader(None)

  headers->Headers.set("Content-Type", "text/csv; charset=UTF-8")
  headers->Headers.set("Content-Disposition", "attachment; filename=\"users.csv\"")

  let csvHeader = "Name,Email,Created At\n"
  let csvRows = users
    ->Array.map(user => `${user.name},${user.email},${user.createdAt}`)
    ->Array.join("\n")

  let fullCsvContent = csvHeader ++ csvRows

  // Since we're outputting raw CSV content (not HTML), we need to use dangerouslyOutputUnescapedContent
  Hjsx.dangerouslyOutputUnescapedContent(fullCsvContent)
}
```

You can then render these whenever someone requests the appropriate paths:

```rescript
render: async ({path}) => {
  switch path {
  | list{"sitemap.xml"} => <SiteMap />
  | list{"users", "export.csv"} =>
    let users = await Database.getAllUsers()
    <UserCsvExport users />
  ...
```

### Handling forms

- `FormDataHelpers`
- `FormData`

### Vite plugin

ResX comes with its own Vite plugin that takes care of all configuration for you. It will:

- Ensure all ResX assets are handled and included properly
- Ensure that Hot Module Reloading works for all assets and that Vite dev mode is properly wired up to your local ResX dev server

> Note: Right now, using ResX with more elaborate Vite config than what's preconfigured for you might be problematic. This will change in the future though so that ResX is just another part of your Vite config. Open issues please when you find use cases you'd like supported but that doesn't work now.

## Static site generation

WIP: Static site generation is easy to do. `StaticExporter.res` and `demo/Exporter.res`.

## Ideas

This section will be expanded as we go along.

- Auth
- Enhanced cookies
- Router abstraction
- Relay for ResX
- Static and semi-static generation
- Suspense and (out of order) streaming
