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
import { ref, shallowRef, inject, onMounted, watch, onUnmounted, computed } from 'vue'
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
    // 布局相关
    automaticLayout: true,
    
    // 格式化
    formatOnType: true,
    formatOnPaste: true,
    formatOnSave: false, // 不自动格式化保存（手动保存）
    
    // 编辑体验
    fontSize: 14,
    lineHeight: 22,
    fontFamily: 'Consolas, "Courier New", monospace',
    
    // 行号和缩进
    lineNumbers: 'on',
    lineNumbersMinChars: 3,
    renderLineHighlight: 'all',
    
    // 制表符
    tabSize: 2,
    insertSpaces: true,
    detectIndentation: false, // 不使用自动检测，使用固定 tabSize
    
    // 代码折叠
    folding: true,
    foldingStrategy: 'auto',
    showFoldingControls: 'always',
    
    // 自动补全
    quickSuggestions: {
        other: true,
        comments: false,
        strings: false
    },
    suggestOnTriggerCharacters: true,
    acceptSuggestionOnCommitCharacter: true,
    acceptSuggestionOnEnter: 'on',
    
    // 小地图和滚动条
    minimap: {
        enabled: true,
        maxColumn: 80
    },
    scrollBeyondLastLine: false,
    scrollbar: {
        vertical: 'auto',
        horizontal: 'auto',
        useShadows: false,
        verticalHasArrows: false,
        horizontalHasArrows: false,
        verticalScrollbarSize: 10,
        horizontalScrollbarSize: 10
    },
    
    // 选择
    selectOnLineNumbers: true,
    roundedSelection: false,
    readOnly: false,
    cursorStyle: 'line',
    
    // 其他
    wordWrap: 'off',
    wrappingIndent: 'indent',
    renderWhitespace: 'selection', // 只在选中时显示空白字符
    renderControlCharacters: false,
    renderIndentGuides: true,
    highlightActiveIndentGuide: true,
    matchBrackets: 'always',
    
    // R 语言特定（Monaco 对 R 的支持有限，但可以启用基础功能）
    autoIndent: 'full',
    bracketPairColorization: {
        enabled: true
    },
    guides: {
        bracketPairs: true,
        indentation: true
    }
}

const code = ref(null)

const editorRef = shallowRef()
function handleMount(editor) {
    editorRef.value = editor
    editor.onKeyDown((e) => {
        // Enter keyCode is 13
        if (e.ctrlKey && (e.keyCode === 13 || e.key === 'Enter')) {
            const currentPosition = editor.getPosition();
            let currentLine = editor.getModel().getLineContent(currentPosition.lineNumber).trim();

            // 如果当前行是空行或只有注释，跳过执行并移到下一行
            if (currentLine === '' || currentLine.startsWith('#')) {
                const nextLineNumber = currentPosition.lineNumber + 1;
                const column = editor.getModel().getLineLength(nextLineNumber) + 1;
                editor.setPosition({ lineNumber: nextLineNumber, column });
                editor.focus();
                e.preventDefault();
                e.stopPropagation();
                return;
            }

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

/**
 * 清理 R 代码：移除空行、纯注释行和行内注释
 * @param {string} code - R 代码
 * @returns {string} 清理后的代码
 * @note 注意：此函数会简单地将 # 及其后的内容视为注释，不处理字符串中的 # 符号
 */
function cleanRCode(code) {
    if (!code) return code;
    
    // 按行分割
    const lines = code.split('\n');
    
    // 处理每一行：移除行内注释，然后过滤空行和纯注释行
    const cleanedLines = lines.map(line => {
        // 去除行内注释（# 及其后面的部分）
        const cleanedLine = line.split('#')[0].trim();
        
        // 只保留有实际代码的行
        return cleanedLine !== '' ? cleanedLine : null;
    }).filter(line => line !== null); // 移除空行
    
    return cleanedLines.join('\n');
}

async function runCode() {
    let selectedCode = editorRef.value.getModel().getValueInRange(editorRef.value.getSelection());
    
    // 如果选中了代码，执行选中的代码
    if (selectedCode && selectedCode.trim()) {
        // 清理代码：移除空行和纯注释行（R 语言本身会处理注释，但这样可以避免执行纯注释行）
        const cleanedCode = cleanRCode(selectedCode);
        
        if (cleanedCode && cleanedCode.trim()) {
            emitter.emit('executeTerminalMethod', { method: 'runCode', payload: cleanedCode });
        } else {
            message.warning('选中的代码只包含注释或空行，没有可执行的代码')
        }
    } else {
        // 如果没有选中代码，提示用户
        message.warning('请先选中要执行的代码，或者使用 Ctrl+Enter 执行当前行')
    }
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
    border-bottom: 1px solid rgba(0, 0, 0, 0.06);
    padding: 8px 12px;
    background-color: rgba(255, 255, 255, 0.6);
    backdrop-filter: blur(10px);
    transition: all 0.2s ease;
}
</style>