<template>
    <div class="box" style="padding:5px;box-sizing: border-box;height:100%">
        <n-space justify="space-between" class="toolbar">
            <n-breadcrumb>
                <n-breadcrumb-item v-for="(item, i) in breadArr" :key="i" @click="navPath(i)">{{ item == '' ? '/' :
                    item }}
                    <template #separator>
                        <n-icon size="20" :component="NavigateNextFilled"
                            style="margin-left: -10px;margin-right:-10px"></n-icon>
                    </template>
                </n-breadcrumb-item>
            </n-breadcrumb>
            <n-space justify="end">
                <n-tooltip>
                    <template #trigger> <n-button text @click="goWd"><n-icon size="20"
                                :component="LocationCurrent" /></n-button></template>工作目录
                </n-tooltip>
                <n-button text><n-icon size="20" :component="FolderAdd" @click="showModalFolder = true" /></n-button>
                <n-button text><n-icon size="20" :component="DocumentAdd" @click="showModalFile = true" /></n-button>
                <n-button text :disabled="!checkedKeys || checkedKeys.length != 1"><n-icon size="20" :component="Delete"
                        @click="showModalDelete = true" /></n-button>
                <n-button text><n-icon size="20" :component="Upload" @click="fileInput.click()" /></n-button>
                <n-button text :disabled="!checkedKeys || checkedKeys.length != 1"><n-icon size="20"
                        :component="Download" @click="handleDownload" /></n-button>
                <!-- <n-button text><n-icon size="20" :component="Save" @click="saveToIndexDB"></n-icon></n-button> -->
            </n-space>
        </n-space>
        <n-tree block-line :data="curTree" :node-props="nodeProps" :checked-keys="checkedKeys"
            @update:checked-keys="updateCheckedKeys" checkable style="margin-left:-23px;height:100%" virtual-scroll>
            <template #empty>
                <n-empty description="无文件">
                </n-empty>
            </template>
        </n-tree>
    </div>
    <n-modal v-model:show="showModalFolder" :mask-closable="false" preset="dialog" title="新建文件夹" positive-text="确认"
        negative-text="取消" @positive-click="addFolder" @negative-click="showModalFolder = false">
        <n-input :allow-input="noSideSpace" v-model:value="folderName" placeholder="文件夹名"></n-input>
    </n-modal>
    <n-modal v-model:show="showModalFile" :mask-closable="false" preset="dialog" title="新建文件" positive-text="确认"
        negative-text="取消" @positive-click="addFile" @negative-click="showModalFile = false">
        <n-input :allow-input="noSideSpace" v-model:value="fileName" placeholder="文件名"></n-input>
    </n-modal>
    <input ref="fileInput" type="file" style="display: none" multiple @change="handleFileChange">
    <n-modal v-model:show="showModalDelete" preset="dialog" title="确认" content="确认删除?" positive-text="确认"
        negative-text="取消" @positive-click="handeleDelete" />
</template>

<script setup>
import { ref, computed, toRaw, inject, onMounted, watch } from "vue"
import { useStore } from 'vuex'
import { Folder, FileTrayFullOutline } from "@vicons/ionicons5";
import { NavigateNextFilled } from "@vicons/material"
import { useMessage, NIcon, NGradientText, NTooltip, NButton } from "naive-ui";
import { FolderAdd, DocumentAdd, LocationCurrent, Delete, Upload, Download, Save } from "@vicons/carbon"
import { saveData, fetchData } from '@/use/indexDB';
const message = useMessage()
const store = useStore()

const showModalFolder = ref(false)
const showModalFile = ref(false)
const showModalDelete = ref(false)
const folderName = ref('')
const fileName = ref('')
const webR = inject('webR')

function updateFileList(payload) { store.commit('updateFileList', payload) }
function updateActiveTabPane(payload) { store.commit('updateActiveTabPane', payload) }

async function goWd() {
    const wd = await webR.evalRString('getwd()')
    curPath.value = wd
}
async function addFolder() {
    if (folderName.value != '') {
        try {
            await webR.FS.mkdir(curPath.value + '/' + folderName.value)
        } catch (err) {
            message.error('创建失败')
        }
        const fileList = await webR.FS.lookupPath('/')
        updateFileList({ fileList })
        folderName.value = null
    }
}

async function addFile() {
    if (fileName.value != '') {
        try {
            const text = '这是一段大段的文本内容，可能包含很多字符...';
            const data = new TextEncoder().encode(text);
            await webR.FS.writeFile(curPath.value + '/' + fileName.value, data)
        } catch (err) {
            message.error('创建失败')
        }
        const fileList = await webR.FS.lookupPath('/')
        updateFileList({ fileList })
        fileName.value = null
    }
}

const curPath = ref('/home/web_user')

function pushFilesOpen(payload) { store.commit('pushFilesOpen', payload) }
function removeFilesOpen(payload) { store.commit('removeFilesOpen', payload) }

const fileList = computed(() => store.state.fileList)
const curList = computed(() => {
    const path = curPath.value
    if (path === '/' || !toRaw(fileList.value)) {
        return fileList.value
    } else {
        return findNodeByPath(path, toRaw(fileList.value))
    }
})
const breadArr = computed(() => {
    if (curPath.value == '/') {
        return ['']
    } else {
        const path = curPath.value
        const arr = path.split('/')
        return arr
    }

})
const curTree = computed(() => {
    function toArray(obj) {
        return Object.entries(obj)
    }
    const res = curList.value
    if (res && !res.mounted) {
        return toArray(res.contents).map(arr => {
            return {
                key: arr[0],
                label: arr[0],
                isFolder: arr[1].isFolder,
                prefix: arr[1].isFolder ? renderIcon(Folder) : renderIcon(FileTrayFullOutline),
                suffix: arr[1].mounted ? renderText('mounted') : ''
            }
        })
    } else if (res && res.mounted) {
        return toArray(res.mounted.root.contents).map(arr => {
            return {
                key: arr[0],
                label: arr[0],
                isFolder: arr[1].isFolder,
                prefix: arr[1].isFolder ? renderIcon(Folder) : renderIcon(FileTrayFullOutline),
                suffix: arr[1].mounted ? renderText('mounted') : ''
            }
        })
    }
})
const nodeProps = ({ option }) => {
    return {
        onClick() {
            if (option.isFolder) {
                curPath.value = breadArr.value.concat(option.key).join('/')
            } else {
                const fileName = breadArr.value.concat(option.key).join('/')
                pushFilesOpen({ fileName })
                updateActiveTabPane({ activeTabPane: fileName })
            }
        }
    }
}

function navPath(i) {
    if (i == 0) {
        curPath.value = '/'
    } else {
        curPath.value = breadArr.value.slice(0, i + 1).join('/')
    }
}

function findNodeByPath(path, node) {
    // 如果路径为空或者路径为'/'，直接返回当前节点
    if (path == '/' || !node) {
        return node;
    }
    // 将路径拆分为当前部分和剩余部分
    const [currentPart, ...remainingParts] = path.split('/').filter(part => part !== '');
    // 查找当前节点的子节点中名称匹配的节点
    let foundNode
    if (node.mounted) {
        console.log(node.mounted.root.contents)
        var arr = Object.entries(node.mounted.root.contents).filter(([key, val]) => key === currentPart)
        foundNode = arr[0][1]
    } else {
        var arr = Object.entries(node.contents).filter(([key, val]) => key === currentPart)
        foundNode = arr[0][1]
    }
    // 如果还有剩余路径，则继续递归查找
    if (remainingParts.length > 0) {
        return findNodeByPath(remainingParts.join('/'), foundNode);
    }
    // 否则返回找到的节点
    return foundNode;
}
function renderIcon(icon) {
    return () => h(NIcon, null, { default: () => h(icon) });
}

function renderText(text) {
    return () => h(NGradientText, { type: 'warning' }, { default: () => text })
}

const noSideSpace = (value) => !value.startsWith(" ") && !value.endsWith(" ") && !value.includes('/')

const checkedKeys = ref([])

function updateCheckedKeys(keys, option, meta) {
    if (meta.action == 'check') {
        checkedKeys.value.push(meta.node.key)
    } else {
        checkedKeys.value = checkedKeys.value.filter(item => item != meta.node.key)
    }
}

watch(curPath, () => {
    checkedKeys.value = []
})
async function handleDownload() {
    const checked = checkedKeys.value[0]
    const path = curPath.value + '/' + checked
    const isFolder = curList.value.contents[checked].isFolder
    const isMounted = curList.value.contents[checked].mounted ? true : false
    let filePath
    let fileName
    if (isFolder) {
        const code = `tar("/${checked}.tar", files="${path}")`
        await webR.evalRVoid(code)
        filePath = `/${checked}.tar`
        fileName = `${checked}.tar`
    } else {
        filePath = path
        fileName = checked
    }
    const fileData = await webR.FS.readFile(filePath);
    const blob = new Blob([fileData], { type: 'application/octet-stream' });
    const downloadLink = document.createElement('a');
    downloadLink.href = URL.createObjectURL(blob);
    downloadLink.download = fileName;
    downloadLink.click();
    URL.revokeObjectURL(downloadLink.href);
    if (isFolder) {
        await webR.FS.unlink(filePath)
    }
}

async function handeleDelete() {
    const path = curPath.value + '/' + checkedKeys.value;
    const isFolder = curList.value.contents[checkedKeys.value].isFolder
    try {
        if (isFolder) {
            await webR.FS.rmdir(path)
        } else {
            await webR.FS.unlink(path)
            removeFilesOpen({ fileName: path })
        }
        checkedKeys.value = checkedKeys.value.filter(item => item != checkedKeys.value)
        const fileList = await webR.FS.lookupPath('/')
        updateFileList({ fileList })
        message.success('删除成功')
    } catch (err) {
        message.error('删除失败')
    }
}

//文件上传
const fileInput = ref(null);

const handleFileChange = async () => {
    const filesToUpload = Array.from(fileInput.value.files);
    for (const file of filesToUpload) {
        const reader = new FileReader();
        reader.onload = async () => {
            try {
                console.log(file.name)
                await webR.FS.writeFile(curPath.value + '/' + file.name, new Uint8Array(reader.result))
                const fileList = await webR.FS.lookupPath('/')
                updateFileList({ fileList })
                message.success('上传成功')
            } catch (error) {
                console.error(`Error uploading file ${file.name}: ${error.message}`);
            }
        };
        reader.readAsArrayBuffer(file);
    }
};

const saveToIndexDB = async () => {
    try {
        const code = `tar("/web_user_files.tar", files="/home/web_user")`
        await webR.evalRVoid(code)
        //await webR.evalRVoid("untar('/web_user_files.tar',exdir='/')")
        const tarFileUint8Array = await webR.FS.readFile('/web_user_files.tar');
        await saveData({ id: '__tar_files', data: tarFileUint8Array });
        console.log('Data saved to IndexDB');
        //await webR.FS.unlink("/web_user_files.tar")
    } catch (error) {
        console.error('Error saving data to IndexDB:', error);
    }
}


onMounted(async () => {
    //const tar = await fetchData('__tar_files')
    //await webR.FS.writeFile('/web_user_files.tar', tar.data)
    //await webR.evalRVoid("untar('/web_user_files.tar',exdir='/home/web_user')")
    //await webR.FS.unlink("/web_user_files.tar")
    const myfileList = await webR.FS.lookupPath('/')
    updateFileList({ fileList: myfileList })
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