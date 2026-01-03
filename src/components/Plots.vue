<template>
    <div class="box" style="padding:0 5px 5px 5px;box-sizing: border-box;height:100%">
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
                    <n-icon size="20" :component="Broom20Filled" />
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
                    <Canvas :imageBitmap="imageBitmap" :width="width" :height="height"></Canvas>
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
import { ref, computed, watch, inject } from "vue"
import { useStore } from 'vuex'
import { PreviousOutline, NextOutline, ZoomIn, Export, Close, Download } from "@vicons/carbon"
import { Broom20Filled } from "@vicons/fluent"

const store = useStore()
const imagesList = computed(() => store.getters.imagesList)
const activePlot = computed(() => store.state.activePlot)
const imageBitmap = computed(() => {
    return imagesList.value[activePlot.value]?.data
})

// 获取 emitter 用于触发 tab 激活
const emitter = inject('emitter', null)

function updateActivePlot(payload) { store.commit('updateActivePlot', payload) }
function clearImages() { store.commit('clearImages') }

// 监听图片列表变化，当有新图时自动激活 Plots tab
const previousImagesLength = ref(0)
watch(imagesList, (newList, oldList) => {
    const currentLength = newList.length
    const previousLength = previousImagesLength.value
    
    // 如果有新图添加（数量增加）
    if (currentLength > previousLength && currentLength > 0) {
        // 检查 Plots 是否在配置的 tabs 中
        const topTabs = store.state.settings?.topTabs || []
        const bottomTabs = store.state.settings?.bottomTabs || []
        
        // 如果 Plots 在 topTabs 或 bottomTabs 中，触发激活事件
        if (topTabs.includes('plots') || bottomTabs.includes('plots')) {
            // 使用 nextTick 确保 DOM 更新完成
            setTimeout(() => {
                if (emitter) {
                    emitter.emit('activatePlotsTab')
                }
            }, 100)
        }
    }
    
    previousImagesLength.value = currentLength
}, { immediate: true })

function go(i) { updateActivePlot({ activePlot: activePlot.value + i }) }
const showModal = ref(false)
const showModalClean = ref(false)

//zoom
const width = ref(800);
const height = ref(600);
const isResizing = ref(false);

const startResize = (event) => {
    event.preventDefault()
    event.stopPropagation()
    
    isResizing.value = true;
    const startX = event.clientX;
    const startY = event.clientY;
    const initialWidth = width.value;
    const initialHeight = height.value;
    
    // 禁用文本选择，提升体验
    document.body.style.userSelect = 'none'
    document.body.style.cursor = 'se-resize'

    let rafId = null

    const onMouseMove = (event) => {
        if (!isResizing.value) return;
        
        event.preventDefault()
        event.stopPropagation()
        
        // 防抖：取消之前的动画帧请求
        if (rafId) {
            cancelAnimationFrame(rafId)
        }
        
        // 节流：使用 requestAnimationFrame 确保流畅更新（约60fps）
        rafId = requestAnimationFrame(() => {
            const deltaX = event.clientX - startX;
            const deltaY = event.clientY - startY;
            
            // 限制最小尺寸
            const newWidth = Math.max(200, initialWidth + deltaX);
            const newHeight = Math.max(200, initialHeight + deltaY);
            
            width.value = newWidth;
            height.value = newHeight;
            
            rafId = null
        })
    };

    const onMouseUp = (event) => {
        event.preventDefault()
        event.stopPropagation()
        
        isResizing.value = false;
        
        // 恢复样式
        document.body.style.userSelect = ''
        document.body.style.cursor = ''
        
        // 清理
        if (rafId) {
            cancelAnimationFrame(rafId)
            rafId = null
        }
        
        window.removeEventListener('mousemove', onMouseMove);
        window.removeEventListener('mouseup', onMouseUp);
    };

    // 使用 passive: false 以便调用 preventDefault
    window.addEventListener('mousemove', onMouseMove, { passive: false });
    window.addEventListener('mouseup', onMouseUp, { passive: false });
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
    width: 16px;
    height: 16px;
    background: linear-gradient(135deg, rgba(56, 141, 207, 0.8) 0%, rgba(45, 183, 201, 0.8) 100%);
    border-radius: 4px 0 12px 0;
    bottom: 0;
    right: 0;
    cursor: se-resize;
    box-shadow: -2px -2px 4px rgba(0, 0, 0, 0.1);
    transition: all 0.2s ease;
}

.resize-handle:hover {
    background: linear-gradient(135deg, rgba(56, 141, 207, 1) 0%, rgba(45, 183, 201, 1) 100%);
    transform: scale(1.1);
}
</style>