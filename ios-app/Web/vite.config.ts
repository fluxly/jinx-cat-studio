import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  // Resolve src-relative imports
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  // Relative base so all asset paths in index.html are ./filename, not /assets/filename.
  // WKWebView loads via file://, so absolute paths don't resolve correctly.
  base: './',
  build: {
    outDir: '../Native/MyIOSApp/Resources/Web',
    emptyOutDir: true,
    // Flatten assets into the output root (no assets/ subdirectory).
    // Xcode copies folder-reference contents to the bundle root, so this keeps
    // the paths in index.html consistent with where the files actually land.
    assetsDir: '',
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
  },
});
