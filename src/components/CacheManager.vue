<template>
  <div class="cache-manager-container">
    <n-card title="缓存管理" size="small" :bordered="false">
      <template #header-extra>
        <n-space>
          <n-button size="small" @click="refreshCacheInfo" :loading="loading">刷新</n-button>
          <n-button size="small" type="error" @click="showClearModal = true" :disabled="loading">
            清空所有缓存
          </n-button>
        </n-space>
      </template>

      <n-scrollbar style="max-height: calc(100vh - 200px);">
        <n-spin :show="loading">
          <n-space vertical style="padding: 8px;">
        <!-- Service Worker 状态 -->
        <n-card size="small" title="Service Worker 状态">
          <n-space vertical>
            <n-space>
              <n-tag :type="swStatus.supported ? 'success' : 'error'">
                {{ swStatus.supported ? '✓ 支持' : '✗ 不支持' }}
              </n-tag>
              <n-tag :type="swStatus.registered ? 'success' : 'warning'">
                {{ swStatus.registered ? '✓ 已注册' : '✗ 未注册' }}
              </n-tag>
            </n-space>
            <n-text depth="3" v-if="swStatus.message">{{ swStatus.message }}</n-text>
          </n-space>
        </n-card>

        <!-- 缓存列表 -->
        <n-card size="small" title="WebR 缓存信息">
          <n-empty v-if="cacheInfos.length === 0" description="暂无缓存数据" />
          <n-space vertical v-else>
            <n-card 
              v-for="cache in cacheInfos" 
              :key="cache.name" 
              size="small" 
              :title="cache.name"
              style="margin-bottom: 8px;"
            >
              <n-space justify="space-between" align="center">
                <n-space vertical>
                  <n-text>缓存条目: {{ cache.count }}</n-text>
                  <n-text>缓存大小: {{ cache.sizeFormatted }}</n-text>
                </n-space>
                <n-button size="small" type="error" @click="clearSingleCache(cache.name)">
                  清除
                </n-button>
              </n-space>
            </n-card>
          </n-space>
        </n-card>

        <!-- 统计信息 -->
        <n-card size="small" title="统计信息" v-if="cacheInfos.length > 0">
          <n-space vertical>
            <n-text>总缓存数: {{ totalCacheCount }}</n-text>
            <n-text>总缓存大小: {{ totalCacheSize }}</n-text>
          </n-space>
        </n-card>
          </n-space>
        </n-spin>
      </n-scrollbar>
    </n-card>

    <!-- 清空确认对话框 -->
    <n-modal v-model:show="showClearModal" preset="dialog" title="确认清空缓存" 
      positive-text="确认" negative-text="取消" 
      @positive-click="clearAllCaches">
      <n-text>确定要清空所有 WebR 缓存吗？这将删除所有已缓存的 R 文件和包，下次访问时需要重新下载。</n-text>
    </n-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useMessage } from 'naive-ui'
import { 
  getAllWebRCacheInfo, 
  clearAllWebRCaches, 
  clearCache,
  checkServiceWorkerStatus 
} from '@/use/cache'

const message = useMessage()
const loading = ref(false)
const cacheInfos = ref([])
const swStatus = ref({})
const showClearModal = ref(false)

const totalCacheCount = computed(() => {
  return cacheInfos.value.reduce((sum, cache) => sum + cache.count, 0)
})

const totalCacheSize = computed(() => {
  const totalBytes = cacheInfos.value.reduce((sum, cache) => sum + cache.size, 0)
  return formatBytes(totalBytes)
})

function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

async function refreshCacheInfo() {
  loading.value = true
  try {
    // 检查 Service Worker 状态
    swStatus.value = await checkServiceWorkerStatus()
    
    // 获取缓存信息
    cacheInfos.value = await getAllWebRCacheInfo()
    
    message.success('缓存信息已更新')
  } catch (error) {
    console.error('Error refreshing cache info:', error)
    message.error('获取缓存信息失败')
  } finally {
    loading.value = false
  }
}

async function clearAllCaches() {
  loading.value = true
  try {
    const success = await clearAllWebRCaches()
    if (success) {
      message.success('所有缓存已清空')
      await refreshCacheInfo()
    } else {
      message.warning('部分缓存清空失败')
    }
  } catch (error) {
    console.error('Error clearing caches:', error)
    message.error('清空缓存失败')
  } finally {
    loading.value = false
    showClearModal.value = false
  }
}

async function clearSingleCache(cacheName) {
  loading.value = true
  try {
    const success = await clearCache(cacheName)
    if (success) {
      message.success(`缓存 ${cacheName} 已清空`)
      await refreshCacheInfo()
    } else {
      message.error('清空缓存失败')
    }
  } catch (error) {
    console.error('Error clearing cache:', error)
    message.error('清空缓存失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  refreshCacheInfo()
})
</script>

<style scoped>
.cache-manager-container {
  height: 100%;
  padding: 8px;
  box-sizing: border-box;
  overflow: hidden;
}

.cache-manager-container :deep(.n-card) {
  margin-bottom: 12px;
}

.cache-manager-container :deep(.n-card-header) {
  padding: 12px;
}

.cache-manager-container :deep(.n-card-body) {
  padding: 12px;
}
</style>

