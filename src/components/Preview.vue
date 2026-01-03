<template>
  <n-modal 
    v-model:show="internalShow" 
    :mask-closable="false" 
    preset="card" 
    title="文件预览" 
    style="width: 90%; max-width: 1200px;"
    @close="handleClose"
  >
    <VueFilesPreview :file="previewFile" v-if="previewFile" />
  </n-modal>
</template>

<script setup>
import { ref, watch, inject, computed } from 'vue'
import { useMessage } from 'naive-ui'
import { VueFilesPreview } from 'vue-files-preview'

const props = defineProps({
  filePath: {
    type: String,
    default: null
  },
  file: {
    type: File,
    default: null
  },
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:show', 'close'])

const webR = inject('webR', null)
const message = useMessage()

const previewFile = ref(null)
const currentFilePath = ref(null)

// 计算属性：内部显示状态
const internalShow = computed({
  get: () => props.show,
  set: (val) => emit('update:show', val)
})

// 监听 show prop 的变化
watch(() => props.show, (newVal) => {
  if (newVal) {
    loadPreview()
  } else {
    previewFile.value = null
    currentFilePath.value = null
  }
})

// 监听 filePath prop 的变化
watch(() => props.filePath, (newVal) => {
  currentFilePath.value = newVal
  if (props.show && newVal) {
    loadPreview()
  }
})

// 监听 file prop 的变化
watch(() => props.file, (newVal) => {
  if (newVal) {
    previewFile.value = newVal
  }
})


// 加载预览文件
async function loadPreview() {
  try {
    // 如果直接提供了 File 对象，直接使用
    if (props.file) {
      previewFile.value = props.file
      return
    }

    // 如果提供了文件路径，需要从 WebR 文件系统读取
    const filePath = props.filePath || currentFilePath.value
    if (filePath && webR) {
      const loadingMessage = message.loading('正在加载文件...', { duration: 0 })
      
      try {
        // 从 WebR 文件系统读取文件
        const fileData = await webR.FS.readFile(filePath)
        
        // 获取文件名
        const fileName = filePath.split('/').pop()
        
        // 创建 File 对象用于预览组件
        const blob = new Blob([fileData], { type: 'application/octet-stream' })
        const file = new File([blob], fileName, { type: blob.type })
        
        previewFile.value = file
        loadingMessage.destroy()
      } catch (error) {
        loadingMessage.destroy()
        throw error
      }
    }
  } catch (error) {
    message.destroyAll()
    console.error('预览文件失败:', error)
    message.error(`预览失败: ${error.message || '未知错误'}`)
    internalShow.value = false
  }
}

function handleClose() {
  internalShow.value = false
}

// 暴露方法供外部调用
defineExpose({
  open: async (filePathOrFile) => {
    if (filePathOrFile instanceof File) {
      previewFile.value = filePathOrFile
      internalShow.value = true
    } else if (typeof filePathOrFile === 'string') {
      // 如果传入的是字符串，更新 filePath 并加载
      currentFilePath.value = filePathOrFile
      internalShow.value = true
      await loadPreview()
    }
  },
  close: handleClose
})
</script>

