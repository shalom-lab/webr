<template>
  <n-theme-editor>
    <n-config-provider :theme-overrides="themeOverrides" :theme="darkMode ? darkTheme : undefined">
      <n-message-provider>
        <n-layout position="absolute" has-sider style="height: 100%;">
          <n-layout-sider bordered collapse-mode="width" :collapsed-width="64" trigger-style=""
            collapsed-trigger-style="" :width="200" :collapsed="collapsed" show-trigger="arrow-circle"
            @collapse="collapsed = true" @expand="collapsed = false">
            <n-menu v-model:value="activeKey" :collapsed="collapsed" :indent="20" :collapsed-width="64"
              :collapsed-icon-size="22" :icon-size="22" :options="menuOptions" />
            <n-space justify="center">
              <n-switch v-model:value="darkMode" />
            </n-space>
          </n-layout-sider>
          <router-view v-slot="{ Component }">
            <keep-alive>
              <component :is="Component" />
            </keep-alive>
          </router-view>
        </n-layout>
      </n-message-provider>
    </n-config-provider>
  </n-theme-editor>
</template>

<script setup>
import { NThemeEditor, NConfigProvider, darkTheme } from 'naive-ui'
import { h, ref, inject, onMounted } from "vue";
import { RouterLink } from 'vue-router'
import { NIcon, useMessage } from "naive-ui";
import { CodeSharp, InsertChartOutlinedTwotone } from "@vicons/material";
import { useStore } from 'vuex'

const darkMode = ref(false)
provide('darkMode', darkMode)

const store = useStore()
function updateFileList(payload) { store.commit('updateFileList', payload) }

function renderIcon(icon) {
  return () => h(NIcon, null, { default: () => h(icon) });
}

const themeOverrides = {
  "common": {
    "primaryColorHover": "#2DB7C9FF",
    "primaryColor": "#388DCFFF"
  }
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
  }
];

const activeKey = ref(null)
const collapsed = ref(true)
provide('collapsed', collapsed)
const webR = inject('webR')
const webRInitializing = ref(true)
provide('webRInitializing', webRInitializing)

onMounted(async () => {
  // 在 onMounted 中获取 message，确保 n-message-provider 已经挂载
  const message = useMessage()
  const loadingBar = useLoadingBar()
  
  try {
    loadingBar.start()
    webRInitializing.value = true
    
    // 检查跨域隔离状态，自动选择通信通道类型
    // channelType: 0 = SharedArrayBuffer (需要跨域隔离), 1 = PostMessage (不需要跨域隔离)
    const isCrossOriginIsolated = self.crossOriginIsolated === true
    const channelType = isCrossOriginIsolated ? 0 : 1
    
    if (!isCrossOriginIsolated) {
      console.warn('页面未启用跨域隔离，使用 PostMessage 通道。某些功能可能受限。')
      message.warning('使用 PostMessage 通道，部分功能可能受限', { duration: 3000 })
    }
    
    await webR.init({ channelType })
    loadingBar.finish()
    webRInitializing.value = false
    const text =
      `demo(graphics)
a<-1:10
b<-mtcars
d<-list(c=4)
e<-function(x){x}
f<-3
m<-matrix(1:100)
`;
    const data = new TextEncoder().encode(text);
    await webR.FS.writeFile('/home/web_user/code.R', data)
    await webR.evalRVoid('webr::mount(mountpoint = "/home/library",source = "https://webr-1257749604.cos.ap-shanghai.myqcloud.com/vfs/library.data")')
    await webR.evalR('.libPaths(c("/home/library",.libPaths()))')
    await webR.evalRVoid("webr::shim_install()")
    const fileList = await webR.FS.lookupPath('/')
    updateFileList({ fileList })
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
