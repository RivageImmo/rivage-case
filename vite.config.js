import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
  ],
  resolve: {
    alias: {
      '~': path.resolve(__dirname, 'app/frontend'),
    },
  },
  server: {
    host: '0.0.0.0',
    port: 3036,
    hmr: {
      host: 'localhost',
      port: 3036,
    },
    allowedHosts: ['vite', 'localhost'],
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
        quietDeps: true,
      },
    },
  },
})
