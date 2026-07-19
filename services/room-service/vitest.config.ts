import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["services/room-service/test/**/*.test.ts"],
    environment: "node",
    coverage: { enabled: false },
  },
});
