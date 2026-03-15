import { defineConfig, type Plugin } from 'vite';
import { readFileSync } from 'fs';
import path from 'path';

// With IIFE format, Vite inlines CSS into the JS bundle instead of extracting it.
// This plugin bypasses that: it emits styles.css as a raw asset and rewrites the
// <link> in index.html to point to it. The CSS is not run through Vite's module
// pipeline so it won't be inlined into bundle.js.
function separateCss(): Plugin {
  const cssSourcePath = path.resolve(__dirname, 'src/styles/app.css');
  return {
    name: 'separate-css',
    apply: 'build',
    // Return empty so Vite doesn't process the CSS through the JS module pipeline
    transform(_code: string, id: string) {
      if (id === cssSourcePath) return { code: '', map: null };
    },
    generateBundle() {
      this.emitFile({
        type: 'asset',
        fileName: 'styles.css',
        source: readFileSync(cssSourcePath, 'utf-8'),
      });
    },
    transformIndexHtml(html: string) {
      // Replace whatever link Vite left with a clean reference to the emitted file
      return html
        .replace(/<link[^>]+app\.css[^>]*>/g, '')
        .replace('</head>', '  <link rel="stylesheet" href="./styles.css">\n</head>');
    },
  };
}

// Strips type="module" and crossorigin from script tags.
// WKWebView under file:// does not execute type="module" scripts reliably.
function plainScriptPlugin(): Plugin {
  return {
    name: 'plain-script',
    transformIndexHtml(html: string) {
      return html
        .replace(/\s+type="module"/g, '')
        .replace(/\s+crossorigin(?:="[^"]*")?/g, '');
    },
  };
}

export default defineConfig({
  plugins: [separateCss(), plainScriptPlugin()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  base: './',
  build: {
    outDir: '../Native/MyIOSApp/Resources/Web',
    emptyOutDir: true,
    assetsDir: '',
    rollupOptions: {
      output: {
        // IIFE bundles everything into one self-executing function — no ES module
        // semantics, works cleanly under file://.
        format: 'iife',
        name: '_app',
        manualChunks: undefined,
        entryFileNames: 'bundle.js',
        chunkFileNames: 'bundle-[name].js',
        assetFileNames: '[name][extname]',
      },
    },
  },
});
