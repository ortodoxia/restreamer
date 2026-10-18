import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: './',
  plugins: [react({
    include: /\.[jt]sx?$/,
    babel: {
      plugins: ['babel-plugin-macros', ['@babel/plugin-transform-react-jsx', { runtime: 'automatic' }]],
    },
  })],
  define: { 'process.env.PUBLIC_URL': JSON.stringify('.') },
  build: {
    outDir: 'build',
    emptyOutDir: true,
    commonjsOptions: { include: [/node_modules/, /src\/locales/] },
  },
  optimizeDeps: { esbuildOptions: { loader: { '.js': 'jsx' } } },
});
