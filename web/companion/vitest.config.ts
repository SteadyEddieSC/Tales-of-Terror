import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["web/companion/test/**/*.test.ts"],
    environment: "jsdom",
    coverage: { enabled: false },
  },
});
