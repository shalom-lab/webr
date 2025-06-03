<template>
    <div class="box" style="padding:5px;box-sizing: border-box;height:100%">
        <n-space size="large" justify="space-between" class="toolbar">
            <n-space>
                <n-button text @click="go(-1)" :disabled="imagesList.length == 0 || activePlot == 0">
                    <n-icon size="20" :component="PreviousOutline" />
                </n-button>
                <n-button text @click="go(1)"
                    :disabled="imagesList.length == 0 || activePlot == Object.keys(imagesList).length - 1">
                    <n-icon size="20" :component="NextOutline" />
                </n-button>
                <n-button text @click="showModal = true" :disabled="imagesList.length == 0">
                    <n-icon size="20" :component="ZoomIn" />
                </n-button>
            </n-space>
            <n-space justify="end">
                <n-button text :disabled="imagesList.length == 0" @click="showModalClean = true">
                    <n-icon size="20" :component="Clean" />
                </n-button>
            </n-space>
        </n-space>
        <n-carousel :current-index="activePlot" :loop="false" :show-dots="false" style="padding:0px;height:100%;">
            <Canvas v-for="item in imagesList" :key="item.id" :imageBitmap="item.data"></Canvas>
        </n-carousel>
    </div>
    <n-modal v-model:show="showModal" :mask-closable="false">
        <n-card style="width:auto" closable content-style="padding:2px" header-style="padding:2px" :bordered="false"
            size="huge" preset="card" aria-modal="true" @close="showModal = false">
            <template #header>
                <n-space>
                    <n-input-number max-length="4" size="small" v-model:value="width" style="width:110px"
                        :show-button="false">
                        <template #prefix>宽度:</template>
                        <template #suffix>px</template>
                    </n-input-number>
                    <n-input-number max-length="4" size="small" v-model:value="height" style="width:110px"
                        :show-button="false">
                        <template #prefix>高度:</template>
                        <template #suffix>px</template>
                    </n-input-number>
                </n-space>

            </template>
            <template #header-extra>
                <n-space style="padding-top:5px;box-sizing:border-box;align-items: center">
                    <n-button text><n-icon size="20" :component="Download" @click="downloadImage" /></n-button>
                </n-space>
            </template>
            <div class="resizable" :style="{ width: width + 'px', height: height + 'px' }">
                <div class="content">
                    <Canvas :imageBitmap="imageBitmap"></Canvas>
                </div>
                <div class="resize-handle" @mousedown="startResize"></div>
            </div>
        </n-card>
    </n-modal>
    <n-modal v-model:show="showModalClean" preset="dialog" title="确认" content="确认删除所有图片?" positive-text="确认"
        negative-text="取消" @positive-click="clearImages" />
</template>

<script setup>
import Canvas from "@/components/Canvas.vue"
import { ref, computed } from "vue"
import { useStore } from 'vuex'
import { PreviousOutline, NextOutline, ZoomIn, Clean, Export, Close, Download } from "@vicons/carbon"

const store = useStore()
const imagesList = computed(() => store.getters.imagesList)
const activePlot = computed(() => store.state.activePlot)
const imageBitmap = computed(() => {
    return imagesList.value[activePlot.value].data
})
function updateActivePlot(payload) { store.commit('updateActivePlot', payload) }
function clearImages() { store.commit('clearImages') }

function go(i) { updateActivePlot({ activePlot: activePlot.value + i }) }
const showModal = ref(false)
const showModalClean = ref(false)

//zoom
const width = ref(800);
const height = ref(600);
const isResizing = ref(false);

const startResize = (event) => {
    isResizing.value = true;
    const startX = event.clientX;
    const startY = event.clientY;
    const initialWidth = width.value;
    const initialHeight = height.value;

    const onMouseMove = (event) => {
        if (!isResizing.value) return;
        const deltaX = event.clientX - startX;
        const deltaY = event.clientY - startY;
        width.value = initialWidth + deltaX;
        height.value = initialHeight + deltaY;
        event.preventDefault()
    };

    const onMouseUp = () => {
        isResizing.value = false;
        window.removeEventListener('mousemove', onMouseMove);
        window.removeEventListener('mouseup', onMouseUp);
        event.preventDefault()
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
};

async function downloadImage() {
    // 创建一个Canvas元素
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');

    // 设置Canvas的尺寸为指定的宽度和高度
    canvas.width = width.value;
    canvas.height = height.value;

    // 将ImageBitmap绘制到Canvas上
    context.drawImage(imageBitmap.value, 0, 0, width.value, height.value);

    // 将Canvas中的图像转换为JPEG格式的数据URL
    const dataURL = canvas.toDataURL('image/jpeg');

    // 创建一个下载链接
    const link = document.createElement('a');
    link.href = dataURL;
    link.download = `plot_${width.value}_${height.value}.jpg`; // 下载文件的名称
    document.body.appendChild(link);

    // 模拟点击下载链接
    link.click();

    // 清理创建的元素
    document.body.removeChild(link);
    canvas.remove();
}
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

.resizable {
    position: relative;
    overflow: hidden;
}

.content {
    width: 100%;
    height: 100%;
}

.resize-handle {
    position: absolute;
    width: 10px;
    height: 10px;
    background-color: black;
    bottom: 0;
    right: 0;
    cursor: se-resize;
}
</style>