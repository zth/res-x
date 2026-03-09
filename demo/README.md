# ResX Demo

## Install

The demo uses the local `rescript-x` package from the repo root, so install both layers:

```sh
bun install
cd demo
bun install
```

The demo `postinstall` script creates `demo/node_modules/rescript-x` as a symlink back to the repo root. That keeps the demo reproducible without recursively copying the whole repository into `node_modules`.

## Local Run

```sh
cd demo
bun run dev
```

For a production-style local run:

```sh
cd demo
bun run build
NODE_ENV=production bun run src/Demo.js
```

The app listens on `PORT` when it is set, and falls back to `4444`.

## Docker Deploy

Build from the repo root so the Docker build can include the parent `rescript-x` package:

```sh
docker build -f demo/Dockerfile -t resx-demo .
```

Run the image:

```sh
docker run --rm -p 4444:4444 -e PORT=4444 resx-demo
```

What the image contains:

- A Bun single-file executable at `/app/demo-app`
- The Vite output in `/app/dist`
- No Bun toolchain or source tree in the runtime image

The container has already been verified to serve both `/start` and hashed asset routes from `/assets/...`.

## Direct SFE Deploy

Build the executable locally:

```sh
cd demo
bun run build:sfe
```

That produces:

- `build/demo-app`
- `dist/`

Deploy both of those together. The executable is not fully self-contained because the generated static routes serve files from `./dist`.

Run it like this:

```sh
cd demo
PORT=4444 NODE_ENV=production ./build/demo-app
```

Important runtime notes:

- Keep `dist/` in the current working directory when you start the executable, or set your service `WorkingDirectory` to the directory that contains `dist/`.
- Files from `demo/assets/` are fingerprinted into `dist/assets/`.
- Files from `demo/public/` are also emitted into `dist/`, so you do not need to deploy `public/` separately.
- If you want to offload assets to a CDN or another static host, you need to change the generated asset URLs and static route strategy. The current setup expects the app process to serve `dist/` itself.

Platform note:

- Bun single-file executables are target-platform specific. If you want to deploy the SFE directly to Linux, build it on Linux for the correct architecture. The Docker image is the safest path because it already builds the Linux executable in-container.
