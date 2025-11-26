# TypeScript with ResX

This guide shows how to use ResX from TypeScript, including TSX-based JSX.

## Setup JSX with TypeScript

ResX ships `.d.ts` for its JSX runtime (`Hjsx`) and SSR (`H`). To author TSX:

1. Install TypeScript in your project (consumer app):

   ```bash
   npm i -D typescript
   ```

2. Configure your `tsconfig.json`:

   ```json
   {
     "compilerOptions": {
     "jsx": "react-jsx",
     "jsxImportSource": "rescript-x",
     "module": "ESNext",
     "moduleResolution": "Bundler",
     "target": "ES2022",
     "lib": ["ES2022", "DOM"]
     }
   }
   ```

3. Write TSX using ResX JSX runtime and render it via `H`:

   ```tsx
   // example.tsx
   import * as H from "rescript-x/H";

   function Page() {
     return <div class="p-4">Hello from TSX + ResX!</div>;
   }

   async function renderHtml() {
     return await H.renderToString(<Page />);
   }
   ```

4. Use with Bun server and ResX handlers:

   ```ts
   // server.ts
   import {
     make as makeHandlers,
     handleRequest,
   } from "rescript-x/Handlers";
   import * as H from "rescript-x/H";

   const handlers = makeHandlers(async (_req) => ({}));

   Bun.serve({
     port: 4444,
     async fetch(request) {
       return handleRequest(handlers, {
         request,
         render: async () => <div>Hello ResX + TS</div>,
       });
     },
   });
   ```

Notes:

- You can import ResX modules directly, e.g. `rescript-x/Handlers` (no `/src` prefix needed).
- The JSX runtime is provided by the package export `rescript-x/jsx-runtime`, so set `jsxImportSource` to `"rescript-x"`.
- Elements and props are intentionally permissive for flexibility; you can layer your own prop typing per component as desired.
