<template>
    <n-modal v-model:show="showModal" :mask-closable="false">
        <n-card style="width:auto" closable content-style="padding:2px" header-style="padding:2px" :bordered="false"
            size="huge" preset="card" aria-modal="true" @close="showModal = false">
            <template #header>
            </template>
            <template #header-extra>
                <n-space style="padding-top:5px;box-sizing:border-box;align-items: center">
                    <n-button text><n-icon size="20" :component="Download" /></n-button>
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
</template>

<script setup>
import Canvas from "@/components/Canvas.vue"
import { ref, computed } from "vue"
import { useStore } from 'vuex'
import { Download } from "@vicons/carbon"
const props = defineProps({
    imageBitmap: Object
})
const imageBitmap = props.imageBitmap


const showModal = ref(true)

const width = ref(600);
const height = ref(400);
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
    };

    const onMouseUp = () => {
        isResizing.value = false;
        window.removeEventListener('mousemove', onMouseMove);
        window.removeEventListener('mouseup', onMouseUp);
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
};
</script>

<style>
.resizable {
    position: relative;
    overflow: hidden;
}

.content {
    width: 100%;
    height: 100%;
    background-color: lightblue;
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