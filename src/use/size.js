import { ref, onMounted, onUnmounted } from 'vue'

export function useSize() {
    const innerWidth = ref(window.innerWidth)
    const innerHeight = ref(window.innerHeight)
    const updateWindowSize = () => {
        innerWidth.value = window.innerWidth;
        innerHeight.value = window.innerHeight;
    };

    // 监听窗口大小变化
    onMounted(() => {
        window.addEventListener('resize', updateWindowSize);
    });

    onUnmounted(() => {
        window.removeEventListener('resize', updateWindowSize);
    });

    return { innerWidth, innerHeight };
};