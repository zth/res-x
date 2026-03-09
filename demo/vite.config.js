import { defineConfig } from "vite";
import resXVitePlugin from "../res-x-vite-plugin.mjs";

export default defineConfig({
  plugins: [
    resXVitePlugin({
      clientDirs: ["client"],
    }),
  ],
  server: {
    port: 9000,
  },
});
