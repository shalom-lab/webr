<template>
    <canvas ref="canvas" :width="props.width" :height="props.height" style="width:100%;height:100%"></canvas>
</template>

<script setup>
import { defineProps, ref, onMounted } from 'vue'

const props = defineProps({
    imageBitmap: Object,
    width: {
        type: Number,
        default: 1008
    },
    height: {
        type: Number,
        default: 1008
    }
})

const canvas = ref(null)

onMounted(() => {
    const context = canvas.value.getContext('2d');
    if (props.imageBitmap) {
        canvas.width = props.imageBitmap.width;
        canvas.height = props.imageBitmap.height;
        context.drawImage(props.imageBitmap, 0, 0, props.width, props.height);
    }
})

</script>

<style scoped>
canvas {
    border: 0px solid black;
}
</style>