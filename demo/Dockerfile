FROM oven/bun:1.3.1-alpine AS build

ENV NODE_ENV=production

WORKDIR /app

COPY bun.lock package.json rescript.json res-x-vite-plugin.mjs ./
COPY client ./client
COPY lib ./lib
COPY src ./src

RUN bun install --frozen-lockfile

WORKDIR /app/demo

COPY demo/bun.lock demo/package.json demo/postcss.config.js demo/rescript.json demo/tailwind.config.js demo/vite.config.js ./
COPY demo/assets ./assets
COPY demo/client ./client
COPY demo/public ./public
COPY demo/scripts ./scripts
COPY demo/src ./src

RUN bun install --frozen-lockfile
RUN bun run build:sfe

FROM alpine:3.20

ENV NODE_ENV=production
ENV PORT=4444

RUN apk add --no-cache ca-certificates libgcc libstdc++

WORKDIR /app

COPY --from=build /app/demo/build/demo-app ./demo-app
COPY --from=build /app/demo/dist ./dist

RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app

USER app

EXPOSE 4444

CMD ["./demo-app"]
