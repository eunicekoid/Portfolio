import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// export default defineConfig({
//   plugins: [react()],
//   server: {
//     proxy: {
//       '/accounts': process.env.VITE_BACKEND_URL,
//       '/categories': process.env.VITE_BACKEND_URL,
//       '/transactions': process.env.VITE_BACKEND_URL,
//       '/budgets': process.env.VITE_BACKEND_URL,
//       '/subcategories': process.env.VITE_BACKEND_URL,
//       '/wolfram': process.env.VITE_BACKEND_URL,
//     },
//   },
// });


export default defineConfig({
  plugins: [react({
    jsxRuntime: 'automatic',
    jsxImportSource: '@emotion/react',
    babel: {
      plugins: ['@emotion/babel-plugin']
    }
  })],
  server: {
    host: true,
    port: 5173,
    watch: {
      usePolling: true
    }
  },
  resolve: {
    alias: {
      'react': 'react',
      'react-dom': 'react-dom'
    }
  },
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'react-router',
      'react-router-dom',
      '@emotion/react',
      '@emotion/styled',
      'date-fns',
      'hoist-non-react-statics'
    ],
    esbuildOptions: {
      target: 'es2020'
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    commonjsOptions: {
      include: [/node_modules/],
      transformMixedEsModules: true
    }
  }
});