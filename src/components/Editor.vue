<template>
    <div class="box">
        <n-space justify="end" style="padding:0 10px;height:20px" class="toolbar">
            <n-button text><n-icon size="20" :component="Save" @click="saveFile"></n-icon></n-button>
            <n-button text><n-icon size="20" :component="PlayFilledAlt" @click="runCode"></n-icon></n-button>
        </n-space>
        <vue-monaco-editor :style="{ width: width + 'px' }" v-model:value="code" :theme="darkMode ? 'vs-dark' : 'vs'"
            language="r" :options="MONACO_EDITOR_OPTIONS" @mount="handleMount" />
    </div>
</template>

<script setup>
import { PlayFilledAlt, Save } from "@vicons/carbon"
import { VueMonacoEditor } from '@guolao/vue-monaco-editor'
import { ref, shallowRef, inject, onMounted, defineProps, watch, onUnmounted } from 'vue'
import { useStore } from 'vuex'
import { useMessage } from 'naive-ui'
import { useSize } from '@/use/size.js'

const { innerWidth, innerHeight } = useSize()

const width = computed(() => {
    return Math.floor((innerWidth.value - (collapsed.value ? 64 : 200)) * split_x.value)
})

const message = useMessage()
const props = defineProps({
    path: String,
});
const webR = inject('webR')
const darkMode = inject('darkMode')
const emitter = inject('emitter');
const split_x = inject('split_x')
const collapsed = inject('collapsed')

const MONACO_EDITOR_OPTIONS = {
    automaticLayout: true,
    formatOnType: true,
    formatOnPaste: true,
}

const code = ref(null)

const editorRef = shallowRef()
function handleMount(editor) {
    editorRef.value = editor
    editor.onKeyDown((e) => {
        if (e.ctrlKey && e.keyCode === monaco.KeyCode.Enter) {
            const currentPosition = editor.getPosition();
            const currentLine = editor.getModel().getLineContent(currentPosition.lineNumber);

            emitter.emit('executeTerminalMethod', { method: 'runCode', payload: currentLine });
            const nextLineNumber = currentPosition.lineNumber + 1;
            const column = editor.getModel().getLineLength(nextLineNumber) + 1;
            editor.setPosition({ lineNumber: nextLineNumber, column });
            editor.focus();
            e.preventDefault(); // 阻止默认行为
            e.stopPropagation()
        }
    });
}

async function saveFile() {
    try {
        const text = code.value;
        const data = new TextEncoder().encode(text);
        await webR.FS.writeFile(props.path, data)
        console.log(data)
        message.success('保存成功')
    } catch (err) {
        message.error('保存失败')
    }

}

async function runCode() {
    const selectedCode = editorRef.value.getModel().getValueInRange(editorRef.value.getSelection());
    emitter.emit('executeTerminalMethod', { method: 'runCode', payload: selectedCode });
}

watch(code, async (oldV, newV) => {
    try {
        const text = newV;
        const data = new TextEncoder().encode(text);
        /*         await webR.FS.writeFile(props.path, data)
                message.success('保存成功') */
    } catch (err) {
        message.error('自动保存失败')
    }
})

onMounted(async () => {
    console.log(props.path)
    const data = await webR.FS.readFile(props.path);
    const text = new TextDecoder().decode(data);
    code.value = text
})

onUnmounted(async () => {
    const text = code.value;
    const data = new TextEncoder().encode(text);
    await webR.FS.writeFile(props.path, data)
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