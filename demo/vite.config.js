import { defineConfig } from "vite";
import resXVitePlugin from "../res-x-vite-plugin.mjs";

const appPort = Number(process.env.PORT ?? 4444);
const vitePort = Number(process.env.VITE_PORT ?? 9000);
const viteHostEnv = process.env.VITE_HOST;
const viteHost =
  viteHostEnv == null ? true : viteHostEnv === "true" ? true : viteHostEnv;

export default defineConfig({
  plugins: [
    resXVitePlugin({
      clientDirs: ["client"],
      serverUri: process.env.RESX_SERVER_URI ?? `http://127.0.0.1:${appPort}`,
    }),
  ],
  server: {
    host: viteHost,
    port: vitePort,
    strictPort: true,
  },
});
