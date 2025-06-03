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

onMounted(async () => {
  await webR.init({ channelType: 0 })
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
})
</script>
