<template>
  <n-layout position="absolute" has-sider style="height: 100%;">
    <n-layout-sider 
      bordered 
      collapse-mode="width" 
      :collapsed-width="64" 
      :width="200" 
      :collapsed="collapsed" 
      show-trigger="arrow-circle"
      :style="siderStyle"
      @collapse="collapsed = true" 
      @expand="collapsed = false">
      <n-menu 
        v-model:value="activeKey" 
        :collapsed="collapsed" 
        :indent="20" 
        :collapsed-width="64"
        :collapsed-icon-size="22" 
        :icon-size="22" 
        :options="menuOptions"
        :style="{ padding: '12px 8px' }"
      />
      <n-space justify="center" :style="{ padding: '16px', borderTop: `1px solid ${darkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.06)'}` }">
        <n-switch v-model:value="darkMode" @update:value="handleDarkModeChange" />
      </n-space>
    </n-layout-sider>
    <router-view v-slot="{ Component }">
      <keep-alive>
        <component :is="Component" />
      </keep-alive>
    </router-view>
  </n-layout>
</template>

<script setup>
import { h, ref, inject, onMounted, provide, watch, computed } from "vue";
import { RouterLink } from 'vue-router'
import { NIcon, useMessage, useLoadingBar, NSwitch, NSpace } from "naive-ui";
import { CodeSharp, InsertChartOutlinedTwotone, SettingsSharp } from "@vicons/material";
import { useStore } from 'vuex'
import { initWebR, TIDYVERSE_PACKAGES, ADDITIONAL_PACKAGES } from '@/use/webrInit'
import { saveData } from '@/use/indexDB'

const darkMode = inject('darkMode')
const store = useStore()
const updateFileList = inject('updateFileList')
const message = useMessage()

// 根据暗黑模式动态计算侧边栏样式
const siderStyle = computed(() => {
  if (darkMode.value) {
    return {
      backgroundColor: 'rgba(30, 30, 30, 0.95)',
      backdropFilter: 'blur(10px)',
      boxShadow: '2px 0 8px rgba(0, 0, 0, 0.3)'
    }
  } else {
    return {
      backgroundColor: 'rgba(255, 255, 255, 0.95)',
      backdropFilter: 'blur(10px)',
      boxShadow: '2px 0 8px rgba(0, 0, 0, 0.06)'
    }
  }
})

// 统一的暗黑模式切换处理函数
async function handleDarkModeChange(newValue) {
  try {
    // 更新 store
    const currentSettings = store.state.settings || {}
    const updatedSettings = { ...currentSettings, darkMode: newValue }
    store.commit('updateSettings', updatedSettings)
    
    // 保存到 IndexedDB
    await saveData({ id: '__app_settings', data: updatedSettings })
  } catch (error) {
    console.error('保存暗黑模式设置失败:', error)
    message.error('保存设置失败')
    // 如果保存失败，回滚状态
    darkMode.value = !newValue
  }
}

// 监听 store 中的 darkMode 变化，同步到注入的 darkMode（用于设置页面修改时同步）
watch(
  () => store.state.settings?.darkMode,
  (newValue) => {
    if (newValue !== undefined && darkMode.value !== newValue) {
      darkMode.value = newValue
    }
  }
)

function renderIcon(icon) {
  return () => h(NIcon, null, { default: () => h(icon) });
}

const menuOptions = [
  {
    label: () => h(RouterLink, { to: { name: "Home" } }, { default: () => "编辑" }),
    key: "home",
    icon: renderIcon(CodeSharp)
  },
  {
    label: () => h(RouterLink, { to: { name: "Chart" } }, { default: () => "图表" }),
    key: "chart",
    icon: renderIcon(InsertChartOutlinedTwotone)
  },
  {
    label: () => h(RouterLink, { to: { name: "Setting" } }, { default: () => "设置" }),
    key: "setting",
    icon: renderIcon(SettingsSharp)
  }
];

const activeKey = ref(null)
const collapsed = ref(true)
provide('collapsed', collapsed)
const webR = inject('webR')
const webRInitializing = ref(true)
provide('webRInitializing', webRInitializing)

// 现在可以安全地在 setup 中调用这些 composables，因为 provider 已经在父组件中
const loadingBar = useLoadingBar()

onMounted(async () => {
  try {
    loadingBar.start()
    webRInitializing.value = true
    
    // 检查跨域隔离状态，自动选择通信通道类型
    // 注意：crossOriginIsolated 不是由 localhost 决定的，而是由 HTTP 响应头决定的
    // - 开发环境：vite.config.js 已配置响应头，所以会启用
    // - GitHub Pages：不支持自定义响应头，会降级到 PostMessage
    // - 其他平台：需要手动配置响应头才能启用
    // 
    // WebR 支持两种通信通道：
    // - SharedArrayBuffer (channelType: 0): 需要跨域隔离，功能完整，支持中断 R 代码执行
    // - PostMessage (channelType: 1): 不需要跨域隔离，但 R 代码无法中断，嵌套 REPL 不工作
    const isCrossOriginIsolated = self.crossOriginIsolated === true
    const channelType = isCrossOriginIsolated ? 0 : 1
    
    if (!isCrossOriginIsolated) {
      console.warn('页面未启用跨域隔离，使用 PostMessage 通道。某些功能可能受限：')
      console.warn('- R 代码无法被中断')
      console.warn('- 嵌套 R REPL (如 browser()) 不工作')
      console.warn('提示：如需完整功能，请配置 Web 服务器添加以下响应头：')
      console.warn('  Cross-Origin-Embedder-Policy: require-corp')
      console.warn('  Cross-Origin-Opener-Policy: same-origin')
      console.warn('注意：GitHub Pages 不支持自定义响应头，建议使用 Vercel/Netlify 等平台')
      message.warning('使用 PostMessage 通道，部分功能可能受限（R 代码无法中断）', { duration: 5000 })
    } else {
      console.log('✓ 跨域隔离已启用，使用 SharedArrayBuffer 通道，所有功能可用')
    }
    
    await webR.init({ channelType })
    
    // 使用统一的初始化函数，静默安装 tidyverse 相关包和其他包
    await initWebR(webR, {
      packagesToInstall: [...TIDYVERSE_PACKAGES, ...ADDITIONAL_PACKAGES],
      onProgress: (msg) => {
        console.log(msg)
      }
    })
    
    const fileList = await webR.FS.lookupPath('/')
    updateFileList({ fileList })
    
    loadingBar.finish()
    webRInitializing.value = false
    message.success('WebR 初始化成功', { duration: 2000 })
  } catch (error) {
    loadingBar.error()
    webRInitializing.value = false
    console.error('WebR 初始化失败:', error)
    
    // 根据错误类型提供不同的提示
    let errorMessage = 'WebR 初始化失败'
    if (error.message) {
      if (error.message.includes('Failed to execute')) {
        errorMessage = 'WebR 初始化失败：可能是缓存问题，请在"缓存"标签中清除所有缓存后重试'
      } else if (error.message.includes('NetworkError') || error.message.includes('fetch')) {
        errorMessage = 'WebR 初始化失败：网络错误，请检查网络连接'
      } else {
        errorMessage = `WebR 初始化失败：${error.message}`
      }
    }
    
    message.error(errorMessage, { duration: 5000 })
  }
})
</script>
