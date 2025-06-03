<template>
    <n-tabs type="card" size="small" style="height:100%" closable pane-style="padding:0px;height:100%"
        :default-value="null" @close="handleClose" :value="activeTabPane" @update:value="changeTab">
        <n-tab-pane :name="item" :tab="item.split('/').reverse()[0]" v-for="item in filesOpen" :key="item"
            display-directive="if">
            <Editor :path="item"></Editor>
        </n-tab-pane>
        <n-tab-pane :name="item" :tab="item" v-for="item in dfsOpen" :key="item">
            <Table :dfname="item"></Table>
        </n-tab-pane>
    </n-tabs>
</template>

<script setup>
import Editor from "@/components/Editor.vue"
import Table from "@/components/Table.vue"
import { ref, shallowRef, inject, onMounted, computed } from 'vue'
import { useStore } from 'vuex'
const store = useStore()

const filesOpen = computed(() => store.state.filesOpen)
const dfsOpen = computed(() => store.state.dfsOpen)

function removeFilesOpen(payload) { store.commit('removeFilesOpen', payload) }
function removeDfsOpen(payload) { store.commit('removeDfsOpen', payload) }

function handleClose(name) {
    console.log(name)
    removeFilesOpen({ fileName: name })
    removeDfsOpen({ dfName: name })
}

const activeTabPane = computed(() => store.state.activeTabPane)
function updateActiveTabPane(payload) { store.commit('updateActiveTabPane', payload) }

function changeTab(activeTabPane) {
    updateActiveTabPane({ activeTabPane })
}
</script>