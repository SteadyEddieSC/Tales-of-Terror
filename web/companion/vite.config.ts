import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";

export default defineConfig({
  root: fileURLToPath(new URL(".", import.meta.url)),
  build: { outDir: "dist", emptyOutDir: true },
  server: {
    host: "127.0.0.1",
    port: 4173,
    strictPort: true,
    fs: { allow: [fileURLToPath(new URL("../..", import.meta.url))] },
  },
  preview: { host: "127.0.0.1", port: 4173, strictPort: true },
});
