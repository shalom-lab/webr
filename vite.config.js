// vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { NaiveUiResolver } from 'unplugin-vue-components/resolvers'
import VueDevTools from 'vite-plugin-vue-devtools'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      imports: [
        'vue',
        {
          'naive-ui': [
            'useDialog',
            'useMessage',
            'useNotification',
            'useLoadingBar'
          ]
        }
      ]
    }),
    Components({
      resolvers: [NaiveUiResolver()]
    }),
    {
      name: "configure-response-headers",
      configureServer: (server) => {
        server.middlewares.use((_req, res, next) => {
          res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
          res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
          next();
        });
      },
    },
    VueDevTools(),
    VitePWA({
      registerType: 'autoUpdate',
      workbox: {
        globPatterns: [
          '**/*.{js,css,html,ico,png,svg}'
        ],
        runtimeCaching: [
          {
            // Match requests ending with R.bin.data, R.bin.js, or R.bin.wasm
            urlPattern: /R\.bin\.(data|js|wasm)$/,
            handler: 'CacheFirst', // Use StaleWhileRevalidate strategy
            options: {
              cacheName: 'R-bin-cache', // Name for the cache
              expiration: {
                maxEntries: 100, // Maximum number of entries
                maxAgeSeconds: 60 * 60 * 24 * 30 // Maximum age in seconds (1 day)
              }
            }
          },
          {
            // Match requests starting with https://webr.r-wasm.org
            urlPattern: /^https:\/\/webr\.r-wasm\.org\//,
            handler: 'NetworkFirst', // Use NetworkFirst strategy
            options: {
              cacheName: 'r-wasm-cache', // Name for the cache
              expiration: {
                maxEntries: 100, // Maximum number of entries
                maxAgeSeconds: 60 * 60 * 24 * 30// Maximum age in seconds (1 day)
              }
            }
          },
          {
            urlPattern: 'https://webr-1257749604.cos.ap-shanghai.myqcloud.com/vfs/library.data',
            handler: 'CacheFirst',
            options: {
              cacheName: 'library-data-cache',
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 60 * 60 * 24 * 30
              }
            }
          },
          {
            urlPattern: 'https://webr-1257749604.cos.ap-shanghai.myqcloud.com/vfs/library.js.metadata',
            handler: 'CacheFirst',
            options: {
              cacheName: 'library-metadata-cache',
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 60 * 60 * 24 * 30
              }
            }
          }
        ]
      },
      devOptions: {
        enabled: true
      }
    })
  ],
  resolve: {
    alias: {
      '@': '/src'
    }
  }
})