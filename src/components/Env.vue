<template>
  <div class="box">
    <n-space class="toolbar" justify="space-between">
      <n-space></n-space>
      <n-space>
        <!-- <n-button text><n-icon size="20" :component="Upload" @click="saveFile"></n-icon></n-button> -->
        <n-button text><n-icon size="20" :component="Save" @click="saveToIndexDB(auto = false)"></n-icon></n-button>
        <n-button text><n-icon size="20" :component="Clean" @click="showModal = true"></n-icon></n-button>
      </n-space>
    </n-space>
    <n-tree block-line :data="objsTree" :show-line="false" :default-expanded-keys="expandedKeys" :node-props="nodeProps"
      style="width:99%;height:100%;margin-right:10px" virtual-scroll></n-tree>
  </div>
  <n-modal v-model:show="showModal" preset="dialog" title="确认" content="你确认清空当前环境?" positive-text="确认"
    negative-text="取消" @positive-click="clearLs" />
</template>

<script setup>
import { computed, ref, toRaw, inject, onMounted, onUnmounted } from "vue";
import { useStore } from 'vuex'
import { FilterListOutlined, AutoAwesomeOutlined, RemoveRedEyeSharp } from "@vicons/material"
import { FunctionMath, DataTable, Save, Clean, Upload, Matrix } from "@vicons/carbon"
import { useMessage, NIcon, NGradientText, NTooltip, NButton, NSpace, NGrid, NGridItem } from "naive-ui";
import { saveData, fetchData } from '@/use/indexDB';

function renderIcon(icon) {
  return () => h(NIcon, { style: { color: 'red' } }, { default: () => h(icon) });
}
function renderLabel(t1, t2, t3, t4 = '') {
  return () => h(NGrid, {
    xGap: '0',
    cols: '24'
  }, () => [h(NGridItem, { span: 5 }, () => t1), h(NGridItem, { span: 5 }, () => t2), h(NGridItem, { span: 5 }, () => t3),
  h(NGridItem, { span: 9 }, () => t4)
  ])
}

const store = useStore()
const message = useMessage()
const webR = inject('webR')

const get_dfs = computed(() => store.getters.get_dfs)
const get_mts = computed(() => store.getters.get_mts)
const get_lis = computed(() => store.getters.get_lis)
const get_fns = computed(() => store.getters.get_fns)
const get_ots = computed(() => store.getters.get_ots)

const code = computed(() => store.state.code)

function updateFileList(payload) { store.commit('updateFileList', payload) }
function updateObjs(payload) { store.commit('updateObjs', payload) }
function updateActiveTabPane(payload) { store.commit('updateActiveTabPane', payload) }

function pushDfsOpen(payload) { store.commit('pushDfsOpen', payload) }

const expandedKeys = ref(['dataframe', 'list', 'matrix', 'function', 'other'])

const nodeProps = ({ option }) => {
  return {
    onClick() {
      console.log(option)
      if (option.type == 'dataframe') {
        pushDfsOpen({ dfName: option.key })
        updateActiveTabPane({ activeTabPane: option.key })
      }
    }
  }
}

const objsTree = computed(() => {
  return [{
    key: 'dataframe',
    label: '数据框',
    prefix: renderIcon(DataTable),
    children: get_dfs.value ? get_dfs.value.map(item => ({
      key: item.name,
      label: renderLabel(item.name, 'dataframe', `${item.nrow}行×${item.ncol}列`),
      suffix: renderIcon(RemoveRedEyeSharp),
      type: 'dataframe',
      children: item.names.map((varname, index) => {
        return {
          key: `${item.name}_${varname}`,
          label: renderLabel(`$ ${varname}`, item.classes[index], `${item.heads[index]}`)
        }
      })
    })) : []
  }, {
    key: 'list',
    label: '列表',
    prefix: renderIcon(FilterListOutlined),
    children: get_dfs.value ? get_lis.value.map(item => ({
      key: item.name,
      label: renderLabel(item.name, 'list', `长度: ${item.length}`)
    })) : []
  }, {
    key: 'matrix',
    label: '矩阵',
    prefix: renderIcon(Matrix),
    children: get_mts.value ? get_mts.value.map(item => ({
      key: item.name,
      label: renderLabel(item.name, 'matrix', `${item.nrow}行×${item.ncol}列`)
    })) : []
  }, {
    key: 'function',
    label: '函数',
    prefix: renderIcon(FunctionMath),
    children: get_dfs.value ? get_fns.value.map(item => ({
      key: item.name,
      label: renderLabel(item.name, 'function', '')
    })) : []
  }, {
    key: 'other',
    label: '其他',
    prefix: renderIcon(AutoAwesomeOutlined),
    children: get_dfs.value ? get_ots.value.map(item => ({
      key: item.name,
      label: renderLabel(item.name, item.mode, `长度: ${item.length}`, item.head)
    })) : []
  }]
})

const saveToIndexDB = async (auto = true) => {
  try {
    const code = `save.image(file='data.RData')`
    await webR.evalRVoid(code)
    const Uint8Array = await webR.FS.readFile('data.RData');
    await saveData({ id: '__RData', data: Uint8Array });
    //await webR.FS.unlink('/data.RData')
    const fileList = await webR.FS.lookupPath('/')
    updateFileList({ fileList })
    if (!auto) message.success('保存成功')
  } catch (error) {
    console.error('Error saving data to IndexDB:', error);
  }
}


async function runR(code) {
  try {
    const shelter = await new webR.Shelter();
    const result = await shelter.captureR(code, {
      withAutoprint: true,
      captureStreams: true,
      captureConditions: true,
      env: webR.objs.globalEnv,
    });
    shelter.purge()
    return result
  } catch (error) {
    message.error('runR error')
  }
}

const timerId = ref(null)

const showModal = ref(false)

const emitter = inject('emitter');

async function clearLs() {
  const code = 'remove(list=ls())';
  await emitter.emit('executeTerminalMethod', { method: 'runCode', payload: code });
}

onMounted(async () => {
  timerId.value = setInterval(saveToIndexDB, 1000 * 60 * 2)

  try {
    await webR.init()
    const RData = await fetchData('__RData')
    if (RData) {
      await webR.FS.writeFile('/obj.RData', RData.data)
      await webR.evalRVoid('load("/obj.RData")')
      await webR.FS.unlink("/obj.RData")
    }
    const res = await runR(code.value.get_ls)
    console.log(res)
    const objs = await res.result.toJs()
    updateObjs({ objs })
    webR.destroy(res)
    webR.destroy(objs)

    console.log('加载RData成功')
  } catch (error) {
    console.error('加载RData出错', error);
  }
})
onUnmounted(() => {
  if (timerId.value) {
    clearInterval(timerId.value);
    timerId.value = null;
  }
})
</script>

<style scoped>
.box {
  width: 100%;
  height: 100%;
  display: grid;
  grid-template-rows: 25px 1fr
}

.toolbar {
  border-bottom: 1px solid #f3f3f356;
}
</style>