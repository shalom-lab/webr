// vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { NaiveUiResolver } from 'unplugin-vue-components/resolvers'
import VueDevTools from 'vite-plugin-vue-devtools'
// import { VitePWA } from 'vite-plugin-pwa' // PWA 功能暂时禁用

export default defineConfig({
  base: '/webr/',
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
    VueDevTools()
    // PWA 功能暂时禁用
    // VitePWA({
    //   registerType: 'autoUpdate',
    //   workbox: {
    //     globPatterns: [
    //       '**/*.{js,css,html,ico,png,svg}'
    //     ],
    //     runtimeCaching: [
    //       // ... 缓存配置 ...
    //     ]
    //   },
    //   devOptions: {
    //     enabled: true
    //   }
    // })
  ],
  resolve: {
    alias: {
      '@': '/src'
    }
  }
})