import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Default environment for unit tests
    environment: 'jsdom',
    // Allow @vitest-environment docblock override per file
    environmentMatchGlobs: [
      ['**/*.ts', 'jsdom'],
    ],
    globals: true,
    include: [
      '../Tests/WebTests/**/*.ts',
      'src/**/*.test.ts',
    ],
  },
});
