<template>
  <div class="setting-container">
    <n-card title="设置" style="height: 100%; overflow-y: auto;">
      <n-space vertical :size="24">
        <!-- 主题设置 -->
        <n-card title="主题设置" size="small">
          <n-space vertical :size="16">
            <n-space align="center" justify="space-between">
              <div>
                <n-text strong>暗黑模式</n-text>
                <br>
                <n-text depth="3" style="font-size: 12px;">切换暗黑/亮色主题</n-text>
              </div>
              <n-switch v-model:value="settings.darkMode" @update:value="saveSettings" />
            </n-space>
          </n-space>
        </n-card>

        <!-- 布局设置 -->
        <n-card title="布局设置" size="small">
          <n-space vertical :size="24">
            <!-- 右上布局 -->
            <n-space vertical :size="8">
              <n-text strong>右上显示</n-text>
              <n-text depth="3" style="font-size: 12px;">选择在右上区域显示的标签页（每个标签页只能在一个位置）</n-text>
              <n-select 
                :value="settings.topTabs" 
                multiple 
                :options="tabOptions" 
                placeholder="选择要在右上显示的标签页"
                @update:value="handleTopTabsChange"
              />
            </n-space>

            <!-- 右下布局 -->
            <n-space vertical :size="8">
              <n-text strong>右下显示</n-text>
              <n-text depth="3" style="font-size: 12px;">选择在右下区域显示的标签页（每个标签页只能在一个位置）</n-text>
              <n-select 
                :value="settings.bottomTabs" 
                multiple 
                :options="tabOptions" 
                placeholder="选择要在右下显示的标签页"
                @update:value="handleBottomTabsChange"
              />
            </n-space>
          </n-space>
        </n-card>

        <!-- 其他设置 -->
        <n-card title="其他设置" size="small">
          <n-space vertical :size="16">
            <n-text depth="3" style="font-size: 12px;">其他配置选项（未来扩展）</n-text>
            <!-- 未来可以添加更多设置选项 -->
          </n-space>
        </n-card>

        <!-- 重置按钮 -->
        <n-space justify="end">
          <n-button @click="resetSettings">重置为默认值</n-button>
        </n-space>
      </n-space>
    </n-card>
  </div>
</template>

<script setup>
import { ref, onMounted, inject } from 'vue'
import { useStore } from 'vuex'
import { useMessage } from 'naive-ui'
import { NCard, NSpace, NText, NSwitch, NSelect, NButton } from 'naive-ui'
import { saveData, fetchData } from '@/use/indexDB'

const store = useStore()
const message = useMessage()
const darkMode = inject('darkMode')

// 默认配置
const defaultSettings = {
  darkMode: false,
  topTabs: ['env'], // 右上显示的 tab 列表
  bottomTabs: ['files', 'plots', 'packages', 'cache'] // 右下显示的 tab 列表
  // 未来可以添加更多配置项
}

// 配置状态
const settings = ref({ ...defaultSettings })

// Tab 选项配置
const tabOptions = [
  { label: 'Env', value: 'env' },
  { label: 'Files', value: 'files' },
  { label: 'Plots', value: 'plots' },
  { label: 'Packages', value: 'packages' },
  { label: 'Cache', value: 'cache' }
]

// 确保每个 tab 只在一个位置（互斥逻辑）
function ensureUniqueTabs() {
  const top = settings.value.topTabs || []
  const bottom = settings.value.bottomTabs || []
  
  // 找出两个数组的交集
  const intersection = top.filter(tab => bottom.includes(tab))
  
  // 如果有交集，从 bottom 中移除（优先保留 top 的选择）
  if (intersection.length > 0) {
    settings.value.bottomTabs = bottom.filter(tab => !intersection.includes(tab))
  }
}

// 处理右上 tabs 变化（确保互斥）
function handleTopTabsChange(newValue) {
  // 先更新 topTabs
  settings.value.topTabs = newValue
  
  // 从 bottomTabs 中移除所有在 newValue 中的项
  const currentBottom = settings.value.bottomTabs || []
  settings.value.bottomTabs = currentBottom.filter(tab => !newValue.includes(tab))
  
  saveSettings()
}

// 处理右下 tabs 变化（确保互斥）
function handleBottomTabsChange(newValue) {
  // 先更新 bottomTabs
  settings.value.bottomTabs = newValue
  
  // 从 topTabs 中移除所有在 newValue 中的项
  const currentTop = settings.value.topTabs || []
  settings.value.topTabs = currentTop.filter(tab => !newValue.includes(tab))
  
  saveSettings()
}

// 加载配置
async function loadSettings() {
  try {
    const saved = await fetchData('__app_settings')
    if (saved && saved.data) {
      settings.value = { ...defaultSettings, ...saved.data }
      // 确保配置有效性（移除重复项）
      ensureUniqueTabs()
      // 应用配置到 store 和暗黑模式
      applySettings()
    } else {
      // 如果没有保存的配置，使用 store 中的默认值
      settings.value = { ...defaultSettings, ...store.state.settings }
      ensureUniqueTabs()
      applySettings()
    }
  } catch (error) {
    console.error('加载设置失败:', error)
    // 使用 store 中的默认值
    settings.value = { ...defaultSettings, ...store.state.settings }
    ensureUniqueTabs()
  }
}

// 保存配置（统一的保存逻辑）
async function saveSettings() {
  try {
    // 使用 JSON 序列化确保对象可以被 IndexedDB 存储
    const dataToSave = JSON.parse(JSON.stringify(settings.value))
    await saveData({ id: '__app_settings', data: dataToSave })
    applySettings()
    message.success('设置已保存', { duration: 2000 })
  } catch (error) {
    console.error('保存设置失败:', error)
    message.error('保存设置失败')
    // 如果保存失败，回滚到 store 中的值
    settings.value = { ...defaultSettings, ...store.state.settings }
  }
}

// 应用配置
function applySettings() {
  // 更新 store 中的配置
  store.commit('updateSettings', settings.value)
  
  // 同步暗黑模式
  if (darkMode && settings.value.darkMode !== undefined) {
    darkMode.value = settings.value.darkMode
  }
}

// 重置配置
async function resetSettings() {
  settings.value = { ...defaultSettings }
  await saveSettings()
  message.success('已重置为默认设置', { duration: 2000 })
}

onMounted(async () => {
  await loadSettings()
})
</script>

<style scoped>
.setting-container {
  width: 100%;
  height: 100%;
  padding: 24px;
  box-sizing: border-box;
  overflow: auto;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
}

.setting-container :deep(.n-card) {
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  transition: box-shadow 0.3s ease;
}

.setting-container :deep(.n-card:hover) {
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.setting-container :deep(.n-card__header) {
  padding: 16px 20px;
  font-weight: 600;
  font-size: 16px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.setting-container :deep(.n-card__content) {
  padding: 20px;
}

.setting-container :deep(.n-card-body) {
  padding: 20px;
}
</style>

