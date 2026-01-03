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
        <n-split direction="vertical" :default-size="0.2" style="height: 100%">
          <template #1>
            <Env />
            <!-- <Console></Console> -->
          </template>
          <template #2>
            <n-tabs type="card" size="small" animated style="height:100%" tab-style="padding:5px 10px"
              :value="activePanel" @update:value="changeTab" pane-style="padding:0px;height:100%"
              pane-wrapper-style="height:100%">
              <n-tab-pane name="files" tab="Files">
                <Files />
              </n-tab-pane>
              <n-tab-pane name="plots" tab="Plots">
                <Plots />
              </n-tab-pane>
              <n-tab-pane name="packages" tab="Packages">
                <Packages />
              </n-tab-pane>
              <n-tab-pane name="cache" tab="缓存">
                <CacheManager />
              </n-tab-pane>
            </n-tabs>
          </template>
        </n-split>
      </template>
    </n-split>
  </n-layout>
</template>
<script setup>
import { ref, provide, computed } from 'vue'
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

const activePanel = computed(() => store.state.activePanel)
function updateActivePanel(payload) { store.commit('updateActivePanel', payload) }
function changeTab(activePanel) {
  updateActivePanel({ activePanel })
}
</script>

<style scoped></style>