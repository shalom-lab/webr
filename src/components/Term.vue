<template>
    <n-space justify="end">
        <n-button text><n-icon size=20 :component="Clean" @click="termRef.clearLog()"></n-icon></n-button>
    </n-space>
    <terminal :class="darkMode ? 'dark' : 'light'" ref='termRef' v-bind="config" @exec-cmd="runCode"></terminal>
</template>

<script setup>
import Terminal from "vue-web-terminal"

import { Clean } from "@vicons/carbon"
import { onMounted, inject, ref } from 'vue'
import { useStore } from "vuex"
import { useMessage } from "naive-ui"

const darkMode = inject('darkMode')

const store = useStore()
function addImages(payload) { store.commit('addImages', payload) }
function updateActivePanel(payload) { store.commit('updateActivePanel', payload) }
function updateObjs(payload) { store.commit('updateObjs', payload) }

const message = useMessage()
const webR = inject('webR')
const emitter = inject('emitter')
const termRef = ref(null)

const code = computed(() => store.state.code)

onMounted(async () => {
    emitter.on('executeTerminalMethod', async ({ method, payload }) => {
        if (method == 'runCode') {
            termRef.value.pushMessage('> ' + payload)
            const result = await runR(payload)
            console.log(result, payload)
            if (result) {
                if (result.images.length > 0) {
                    addImages({ images: result.images })
                    updateActivePanel({ activePanel: 'plots' })
                }
                var msg = result.output.map((output) => {
                    let cla = null;
                    switch (output.type) {
                        case 'stdout':
                            cla = '';
                            break;
                        case 'stderr':
                            cla = 'error';
                            break;
                    }
                    return { type: 'normal', content: output.data, class: cla }
                })
            }
            const res = await runR(code.value.get_ls)
            const objs = await res.result.toJs()
            updateObjs({ objs })
            webR.destroy(res)
            webR.destroy(objs)
            if (msg) { termRef.value.pushMessage(msg) }
        }
    });
    for (; ;) {
        const output = await webR.read();
        switch (output.type) {
            case 'stdout':
                termRef.value.pushMessage(output.data)
                break;
            case 'stderr':
                termRef.value.pushMessage({ type: 'normal', content: output.data, calss: 'error' })
                break;
            case 'prompt':
                break;
            default:
                termRef.value.pushMessage(`Unhandled output type: ${output.type}.`)
        }
    }
})

const config = {
    context: '',
    'show-header': false,
    'init-log': null
}

async function runR(code) {
    code = 'webr::shim_install() \n' + code
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
async function runCode(key, command, success, failed) {
    try {
        const result = await runR(command)
        if (result.images.length > 0) {
            addImages({ images: result.images })
            updateActivePanel({ activePanel: 'plots' })
        }
        var msg = result.output.map((output) => {
            let cla = null;
            switch (output.type) {
                case 'stdout':
                    cla = '';
                    break;
                case 'stderr':
                    cla = 'error';
                    break;
            }
            return { type: 'normal', content: output.data, class: cla }
        })
        const res = await runR(code.value.get_ls)
        await webR.evalRVoid("remove(list=ls(pattern='^webr_'))")
        const objs = await res.result.toJs()
        updateObjs({ objs })
        webR.destroy(res)
        webR.destroy(objs)
        if (msg) { success(msg) } else { success() }
    } catch (err) {
        message.error('runCode error')
        success()
    }
}
</script>

<style scoped>
.term {
    width: 100%;
    display: grid;
    grid-template-rows: 20px 1fr;
}

.dark {
    --t-main-background-color: #191b24;
    --t-main-font-color: #fff;
    --t-window-box-shadow: 0 0 40px 1px rgb(0 0 0 / 20%);
    --t-header-background-color: #959598;
    --t-header-font-color: white;
    --t-tag-font-color: #fff;
    --t-cursor-color: #fff;
    --t-cmd-key-color: yellow;
    --t-cmd-arg-color: #c0c0ff;
    --t-cmd-splitter-color: #808085;
    --t-link-color: antiquewhite;
    --t-link-hover-color: white;
    --t-table-border: 1px dashed #fff;
    --t-selection-font-color: black;
    --t-selection-background-color: white;
    --t-cmd-help-background-color: black;
    --t-cmd-help-code-font-color: #fff;
    --t-cmd-help-code-background-color: rgba(0, 0, 0, 0);
    --t-cmd-help-msg-color: #ffffff87;
    --t-cmd-help-box-shadow: 0px 0px 0px 4px rgb(255 255 255 / 20%);
    --t-text-editor-floor-background-color: rgb(72 69 69);
    --t-text-editor-floor-close-btn-color: #bba9a9;
    --t-text-editor-floor-save-btn-color: #00b10e;
    --t-text-editor-floor-btn-hover-color: #befcff;
    --t-json-background-color: rgba(0, 0, 0, 0);
    --t-json-value-obj-color: #bdadad;
    --t-json-value-bool-color: #cdc83c;
    --t-json-value-number-color: #f3c7fb;
    --t-json-ellipsis-background-color: #674848;
    --t-json-more-background-webkit: -webkit-linear-gradient(top, rgba(0, 0, 0, 0) 20%, rgb(255 255 255 / 10%) 100%);
    --t-json-more-background: linear-gradient(to bottom, rgba(0, 0, 0, 0) 20%, rgb(255 255 255 / 10%) 100%);
    --t-json-deep-selector-border-color: rgb(249 249 249 / 52%);
    --t-code-default-background-color: rgb(39 50 58);
}

.light {
    font-size: 20px;
    --t-main-background-color: #fff;
    --t-main-font-color: #000;
    --t-window-box-shadow: 0 0 40px 1px rgb(0 0 0 / 20%);
    --t-header-background-color: #4b474c;
    --t-header-font-color: white;
    --t-tag-font-color: #fff;
    --t-cursor-color: #000;
    --t-cmd-key-color: #834dff;
    --t-cmd-arg-color: #c0c0ff;
    --t-cmd-splitter-color: #808085;
    --t-link-color: #02505e;
    --t-link-hover-color: #17b2d2;
    --t-table-border: 1px dashed #565151;
    --t-selection-font-color: white;
    --t-selection-background-color: #2a2626;
    --t-cmd-help-background-color: white;
    --t-cmd-help-code-font-color: rgba(0, 0, 0, .8);
    --t-cmd-help-code-background-color: #f7f7f9;
    --t-cmd-help-msg-color: #c5a5a5;
    --t-cmd-help-box-shadow: 0px 0px 0px 4px rgb(0 0 0 / 20%);
    --t-text-editor-floor-background-color: rgba(0, 0, 0, .1);
    --t-text-editor-floor-close-btn-color: #9a7070;
    --t-text-editor-floor-save-btn-color: #00b10e;
    --t-text-editor-floor-btn-hover-color: #652222;
    --t-json-background-color: rgba(0, 0, 0, 0);
    --t-json-value-obj-color: #bdadad;
    --t-json-value-bool-color: #cdc83c;
    --t-json-value-number-color: #a625be;
    --t-json-ellipsis-background-color: #f5f5f5;
    --t-json-more-background-webkit: -webkit-linear-gradient(top, rgba(0, 0, 0, 0) 20%, rgb(255 255 255 / 10%) 100%);
    --t-json-more-background: linear-gradient(to bottom, rgba(0, 0, 0, 0) 20%, rgb(255 255 255 / 10%) 100%);
    --t-json-deep-selector-border-color: rgb(249 249 249 / 52%);
    --t-code-default-background-color: rgb(227 239 248);
}
</style>