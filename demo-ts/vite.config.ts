import { defineConfig } from "vite";
import resXVitePlugin from "../res-x-vite-plugin.mjs";

export default defineConfig({
  plugins: [resXVitePlugin()],
  server: {
    port: 9000,
  },
});

