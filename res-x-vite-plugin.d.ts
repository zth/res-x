import type { Plugin } from "vite";

export interface ResXVitePluginOptions {
  /** Directory where generated files are written. Default: "src/__generated__" */
  generated?: string;
  /** Backend server URI to proxy to in dev. Default: "http://localhost:4444" */
  serverUri?: string;
  /** Path to the ResX client bundle. Default: "node_modules/rescript-x/src/ResXClient.js" */
  resXClientLocation?: string;
}

export default function resXVitePlugin(options?: ResXVitePluginOptions): Plugin;

