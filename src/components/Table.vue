<template>
    <div class="box">
        <n-space justify="end" style="padding:0 10px;height:20px" class="toolbar">
            <n-popover trigger="click" placement="bottom">
                <template #trigger>
                    <n-button text><n-icon size="20" :component="ChatBot"></n-icon></n-button>
                </template>
                <div style="width:400px">
                    <n-space justify="end">
                        <n-button size="small" text>
                            <n-icon size="20" :component="Copy" @click="CopyCode"></n-icon>
                        </n-button>
                    </n-space>
                    <n-input v-model:value="prompt" type="textarea" />
                </div>

            </n-popover>
            <n-button text><n-icon size="20" :component="Export" @click="exportCsv"></n-icon></n-button>
        </n-space>
        <n-data-table v-if="columns.length > 0" :columns="columns" :data="data" :pagination="true" :bordered="false"
            size="small" :max-height="split_y * innerHeight - 170" :scroll-x="1000" :loading="loading"
            :style="{ width: width + 'px' }" ref="tableRef" />
    </div>
</template>

<script setup>
import { Export, ChatBot, Copy } from "@vicons/carbon"
import { VueMonacoEditor } from '@guolao/vue-monaco-editor'
import { ref, shallowRef, inject, onMounted, defineProps, watch, onUnmounted, h } from 'vue'
import { useStore } from 'vuex'
import { useMessage, NTooltip, NGradientText } from 'naive-ui'
import { useSize } from '@/use/size.js'


const message = useMessage()
const props = defineProps({
    dfname: String,
});
const webR = inject('webR')
const split_y = inject('split_y')
const split_x = inject('split_x')
const collapsed = inject('collapsed')
const { innerWidth, innerHeight } = useSize()

const width = computed(() => {
    return Math.floor((innerWidth.value - (collapsed.value ? 64 : 200)) * split_x.value)
})

const data = ref(null)
const columns = ref([])
const loading = ref(true)
const tableRef = ref();

const exportCsv = () => tableRef.value?.downloadCsv({
    fileName: `${props.dfname}_sorted`,
    keepOriginalData: false
});
const prompt = ref(null)

const CopyCode = async () => {
    const content = prompt.value;
    try {
        await navigator.clipboard.writeText(content);
        message.success("内容已复制到剪切板！发给GPT吧");
    } catch (error) {
        console.error("无法复制到剪切板：", error);
    }
}

const renderTooltip = (trigger, content) => {
    return h(NTooltip, null, {
        trigger: () => trigger,
        default: () => content
    })
}

const renderBadgeWithAvatar = (value) => {
    return h('n-badge', { props: { value: value, max: 15 } }, [
        h('n-avatar')
    ]);
}

onMounted(async () => {
    const res = await webR.evalR(props.dfname);
    const classes = await webR.evalRRaw(`unname(sapply(${props.dfname},class))`, 'string[]')
    const rowNames = await webR.evalRRaw(`rownames(${props.dfname})`, 'string[]')
    const df = await res.toD3()
    data.value = df.map((data, index) => {
        return {
            ...data,
            key: rowNames[index]
        }
    })
    columns.value = Object.keys(df[0]).map((item, index) => {
        return {
            key: item,
            title: `${item}(${classes[index].slice(0, 3)})`,
            resizable: true,
            sorter: 'default'
        }
    })
    prompt.value = `R语言中,名为${props.dfname}的数据框共有${df.length}行${Object.keys(df[0]).length}列,数据框所含变量分别为${Object.keys(df[0]).join()}，类型依次为${classes.join()}，我想要:`
    loading.value = false
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