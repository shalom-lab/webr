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
import { ref, computed, defineProps } from "vue"
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
    width: 10px;
    height: 10px;
    background-color: black;
    bottom: 0;
    right: 0;
    cursor: se-resize;
}
</style>