<template>
  <n-theme-editor>
    <n-config-provider :theme-overrides="themeOverrides" :theme="darkMode ? darkTheme : undefined">
      <n-message-provider>
        <n-loading-bar-provider>
          <AppContent />
        </n-loading-bar-provider>
      </n-message-provider>
    </n-config-provider>
  </n-theme-editor>
</template>

<script setup>
import { NThemeEditor, NConfigProvider, darkTheme, NLoadingBarProvider } from 'naive-ui'
import { ref, provide, watch, computed, onMounted } from "vue";
import { useStore } from 'vuex'
import AppContent from './components/AppContent.vue'
import { fetchData } from '@/use/indexDB'

const store = useStore()

// 暗黑模式，从 store 读取，或使用默认值
const darkMode = ref(store.state.settings?.darkMode || false)
provide('darkMode', darkMode)

// 监听 store 中的配置变化
watch(
  () => store.state.settings?.darkMode,
  (newValue) => {
    if (newValue !== undefined) {
      darkMode.value = newValue
    }
  },
  { immediate: true }
)

// 加载保存的配置
onMounted(async () => {
  try {
    const saved = await fetchData('__app_settings')
    if (saved && saved.data) {
      // 确保数据是纯对象（不是响应式对象）
      const settingsData = JSON.parse(JSON.stringify(saved.data))
      store.commit('updateSettings', settingsData)
      if (settingsData.darkMode !== undefined) {
        darkMode.value = settingsData.darkMode
      }
    }
  } catch (error) {
    console.error('加载设置失败:', error)
  }
})

function updateFileList(payload) { store.commit('updateFileList', payload) }
provide('updateFileList', updateFileList)

const themeOverrides = {
  "common": {
    "primaryColor": "#388DCFFF",
    "primaryColorHover": "#2DB7C9FF",
    "primaryColorPressed": "#1A9BB3FF",
    "primaryColorSuppl": "#4A9DD5FF",
    "fontFamily": "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'Helvetica Neue', Helvetica, Arial, sans-serif",
    "fontFamilyMono": "'SF Mono', 'Monaco', 'Inconsolata', 'Roboto Mono', 'Source Code Pro', 'Consolas', 'Courier New', monospace",
    "borderRadius": "6px",
    "borderRadiusSmall": "4px",
    "borderRadiusMedium": "6px",
    "borderRadiusLarge": "8px",
    "heightSmall": "28px",
    "heightMedium": "34px",
    "heightLarge": "40px",
    "fontSizeSmall": "12px",
    "fontSizeMedium": "14px",
    "fontSizeLarge": "16px",
    "fontWeight": "400",
    "fontWeightStrong": "500",
    "opacity1": "0.82",
    "opacity2": "0.72",
    "opacity3": "0.52",
    "opacity4": "0.38",
    "opacity5": "0.24",
    "opacityDisabled": "0.5"
  },
  "Card": {
    "borderRadius": "8px",
    "color": "#FFFFFF",
    "colorModal": "#FFFFFF",
    "colorTarget": "#FFFFFF",
    "boxShadow": "0 2px 8px 0 rgba(0, 0, 0, 0.08)",
    "boxShadowHover": "0 4px 12px 0 rgba(0, 0, 0, 0.12)",
    "colorEmbedded": "#FFFFFF",
    "colorEmbeddedModal": "#FFFFFF",
    "colorEmbeddedPopover": "#FFFFFF"
  },
  "DataTable": {
    "borderRadius": "6px"
  },
  "Input": {
    "borderRadius": "6px"
  },
  "Button": {
    "borderRadiusSmall": "4px",
    "borderRadiusMedium": "6px",
    "borderRadiusLarge": "8px",
    "fontWeight": "500",
    "fontWeightText": "400",
    "fontWeightGhost": "500",
    "heightSmall": "28px",
    "heightMedium": "34px",
    "heightLarge": "40px"
  },
  "Menu": {
    "borderRadius": "6px",
    "itemBorderRadius": "6px"
  },
  "Tabs": {
    "tabBorderRadius": "6px",
    "panePaddingSmall": "8px",
    "panePaddingMedium": "12px",
    "panePaddingLarge": "16px"
  },
  "Select": {
    "borderRadius": "6px"
  },
  "Switch": {
    "railBorderRadius": "12px",
    "buttonBorderRadius": "10px"
  }
}
provide('themeOverrides', themeOverrides)
</script>
