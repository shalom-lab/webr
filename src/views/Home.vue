<template>
  <n-layout>
    <n-split direction="horizontal" v-model:size="split_x" style="height: 100%">
      <template #1>
        <n-split direction="vertical" v-model:size="split_y" style="height: 100%">
          <template #1>
            <Editors></Editors>
          </template>
          <template #2>
            <Term></Term>
          </template>
        </n-split>
      </template>
      <template #2>
        <n-split 
          v-if="topTabs.length > 0 && bottomTabs.length > 0" 
          direction="vertical" 
          :default-size="0.5" 
          style="height: 100%">
          <template #1>
            <n-tabs type="card" size="small" animated style="height:100%" tab-style="padding:5px 10px"
              :value="activeTopPanel" @update:value="changeTopTab" pane-style="padding:0px;height:100%"
              pane-wrapper-style="height:100%">
              <n-tab-pane v-for="tab in visibleTopTabs" :key="tab.name" :name="tab.name" :tab="tab.label">
                <component :is="tab.component" />
              </n-tab-pane>
            </n-tabs>
          </template>
          <template #2>
            <n-tabs type="card" size="small" animated style="height:100%" tab-style="padding:5px 10px"
              :value="activeBottomPanel" @update:value="changeBottomTab" pane-style="padding:0px;height:100%"
              pane-wrapper-style="height:100%">
              <n-tab-pane v-for="tab in visibleBottomTabs" :key="tab.name" :name="tab.name" :tab="tab.label">
                <component :is="tab.component" />
              </n-tab-pane>
            </n-tabs>
          </template>
        </n-split>
        <n-tabs v-else type="card" size="small" animated style="height:100%" tab-style="padding:5px 10px"
          :value="activePanel" @update:value="changeTab" pane-style="padding:0px;height:100%"
          pane-wrapper-style="height:100%">
          <n-tab-pane v-for="tab in allVisibleTabs" :key="tab.name" :name="tab.name" :tab="tab.label">
            <component :is="tab.component" />
          </n-tab-pane>
        </n-tabs>
      </template>
    </n-split>
  </n-layout>
</template>
<script setup>
import { ref, provide, computed, watch } from 'vue'
import { useStore } from 'vuex'
import Plots from '@/components/Plots.vue'
import Files from '@/components/Files.vue'
import Editors from '@/components/Editors.vue'
import Term from '@/components/Term.vue'
import Env from '@/components/Env.vue'
import CacheManager from '@/components/CacheManager.vue'
import Packages from '@/components/Packages.vue'
import mitt from 'mitt';
const store = useStore()
const emitter = mitt();

provide('emitter', emitter);
const split_x = ref(0.6)
const split_y = ref(0.5)
provide('split_x', split_x)
provide('split_y', split_y)

// 从 store 获取配置
const topTabs = computed(() => store.state.settings?.topTabs || ['env'])
const bottomTabs = computed(() => store.state.settings?.bottomTabs || ['files', 'plots', 'packages', 'cache'])

// 定义所有可用的 tab
const allTabDefinitions = {
  env: { name: 'env', label: 'Env', component: Env },
  files: { name: 'files', label: 'Files', component: Files },
  plots: { name: 'plots', label: 'Plots', component: Plots },
  packages: { name: 'packages', label: 'Packages', component: Packages },
  cache: { name: 'cache', label: 'Cache', component: CacheManager }
}

// 根据配置过滤出可见的 tab
const visibleTopTabs = computed(() => {
  return topTabs.value
    .map(tabName => allTabDefinitions[tabName])
    .filter(tab => tab !== undefined)
})

const visibleBottomTabs = computed(() => {
  return bottomTabs.value
    .map(tabName => allTabDefinitions[tabName])
    .filter(tab => tab !== undefined)
})

const allVisibleTabs = computed(() => {
  const all = [...topTabs.value, ...bottomTabs.value]
  return all
    .map(tabName => allTabDefinitions[tabName])
    .filter(tab => tab !== undefined)
})

// 独立的 activePanel 状态（用于单栏显示时）
const activePanel = computed(() => store.state.activePanel)

// 上方 tabs 的独立状态
const activeTopPanel = ref(topTabs.value.length > 0 ? topTabs.value[0] : null)

// 下方 tabs 的独立状态
const activeBottomPanel = ref(bottomTabs.value.length > 0 ? bottomTabs.value[0] : null)

// 监听配置变化，更新默认选中的 tab
watch(topTabs, (newTabs) => {
  if (newTabs.length > 0) {
    // 如果当前选中的 tab 不在新的列表中，则选择第一个
    if (!newTabs.includes(activeTopPanel.value)) {
      activeTopPanel.value = newTabs[0]
    }
  } else {
    activeTopPanel.value = null
  }
}, { immediate: true })

watch(bottomTabs, (newTabs) => {
  if (newTabs.length > 0) {
    // 如果当前选中的 tab 不在新的列表中，则选择第一个
    if (!newTabs.includes(activeBottomPanel.value)) {
      activeBottomPanel.value = newTabs[0]
    }
  } else {
    activeBottomPanel.value = null
  }
}, { immediate: true })

function updateActivePanel(payload) { store.commit('updateActivePanel', payload) }
function changeTab(activePanel) {
  updateActivePanel({ activePanel })
}

function changeTopTab(panel) {
  activeTopPanel.value = panel
}

function changeBottomTab(panel) {
  activeBottomPanel.value = panel
}

// 监听 emitter 事件，当有新图时自动激活 Plots tab
emitter.on('activatePlotsTab', () => {
  // 检查 Plots 在哪个位置（top 或 bottom）
  if (topTabs.value.includes('plots')) {
    activeTopPanel.value = 'plots'
  } else if (bottomTabs.value.includes('plots')) {
    activeBottomPanel.value = 'plots'
  } else if (allVisibleTabs.value.some(tab => tab.name === 'plots')) {
    // 如果是在单栏模式下
    updateActivePanel({ activePanel: 'plots' })
  }
})
</script>

<style scoped></style>
