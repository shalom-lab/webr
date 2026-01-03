<template>
    <canvas ref="canvas" :width="props.width" :height="props.height" style="width:100%;height:100%"></canvas>
</template>

<script setup>
import { ref, onMounted, watch, nextTick } from 'vue'

const props = defineProps({
    imageBitmap: Object,
    width: {
        type: Number,
        default: null  // 如果为 null，使用 imageBitmap 的原始尺寸
    },
    height: {
        type: Number,
        default: null  // 如果为 null，使用 imageBitmap 的原始尺寸
    }
})

const canvas = ref(null)
let rafId = null
let isDrawing = false

// 绘制图片的函数
function drawImage() {
    if (!canvas.value || !props.imageBitmap || isDrawing) {
        return
    }
    
    isDrawing = true
    
    // 使用 requestAnimationFrame 优化性能
    if (rafId) {
        cancelAnimationFrame(rafId)
    }
    
    rafId = requestAnimationFrame(() => {
        const context = canvas.value.getContext('2d')
        
        // 确定 canvas 的实际尺寸
        const canvasWidth = props.width || props.imageBitmap.width
        const canvasHeight = props.height || props.imageBitmap.height
        
        // 设置 canvas 的实际尺寸
        canvas.value.width = canvasWidth
        canvas.value.height = canvasHeight
        
        // 清除画布
        context.clearRect(0, 0, canvasWidth, canvasHeight)
        
        // 绘制图片（如果指定了 width/height，会缩放到指定尺寸）
        context.drawImage(
            props.imageBitmap, 
            0, 0, 
            canvasWidth, 
            canvasHeight
        )
        
        isDrawing = false
        rafId = null
    })
}

onMounted(async () => {
    await nextTick()
    drawImage()
})

// 监听 props 变化，重新绘制
watch(
    () => props.imageBitmap,
    async () => {
        await nextTick()
        drawImage()
    }
)

// 单独监听 width/height，使用 requestAnimationFrame 优化（resize 时更流畅）
watch(
    () => [props.width, props.height],
    () => {
        drawImage()
    }
)

</script>

<style scoped>
canvas {
    border: 0px solid black;
}
</style>