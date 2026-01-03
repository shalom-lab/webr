<template>
  <div class="box">
    <n-space justify="space-between" class="toolbar">
      <n-space>
        <n-button text @click="refreshPackages">
          <n-icon size="20" :component="RefreshOutlined" />
        </n-button>
        <n-checkbox v-model:checked="showLoadedOnly">
          只显示已加载的包
        </n-checkbox>
      </n-space>
      <n-space justify="end">
        <n-input
          v-model:value="searchText"
          placeholder="搜索包名..."
          clearable
          style="width: 200px"
        />
      </n-space>
    </n-space>
    <div class="table-container">
      <n-data-table
        :columns="columns"
        :data="filteredPackages"
        :loading="loading"
        :pagination="pagination"
        size="small"
        virtual-scroll
        :scrollbar-props="{ trigger: 'none' }"
      >
        <template #empty>
          <n-empty description="暂无已安装的包">
          </n-empty>
        </template>
      </n-data-table>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, reactive, inject, onMounted, h } from 'vue'
import { NDataTable, NCheckbox, NIcon, NButton, NInput, NSpace, NEmpty, useMessage } from 'naive-ui'
import { RefreshOutlined } from '@vicons/material'

const webR = inject('webR')
const message = useMessage()

const packages = ref([])
const loadedPackages = ref([])
const loading = ref(false)
const searchText = ref('')
const showLoadedOnly = ref(false)

// 等待 WebR 初始化完成
async function waitForWebRInit() {
  // 检查 webR 实例是否存在
  if (!webR) {
    throw new Error('WebR 实例不存在')
  }
  
  // 如果已经初始化，直接返回
  if (webR.objs && webR.objs.globalEnv) {
    return
  }
  
  const maxWait = 10000
  const interval = 100
  const startTime = Date.now()
  
  while (Date.now() - startTime < maxWait) {
    // 更严格的检查
    if (webR && webR.objs && webR.objs.globalEnv) {
      return
    }
    await new Promise(resolve => setTimeout(resolve, interval))
  }
  
  throw new Error('WebR 初始化超时，请刷新页面重试')
}

// 执行 R 代码
async function runR(code) {
  try {
    // 更严格的检查
    if (!webR) {
      throw new Error('WebR 实例不存在')
    }
    if (!webR.objs) {
      throw new Error('WebR 对象未初始化，请等待初始化完成')
    }
    if (!webR.objs.globalEnv) {
      throw new Error('WebR 全局环境未初始化，请等待初始化完成')
    }
    
    const shelter = await new webR.Shelter()
    const result = await shelter.captureR(code, {
      withAutoprint: true,
      captureStreams: true,
      captureConditions: true,
      env: webR.objs.globalEnv,
    })
    shelter.purge()
    return result
  } catch (error) {
    console.error('runR 执行错误:', error)
    message.error(`执行 R 代码时出错: ${error.message || '未知错误'}`)
    throw error
  }
}

// 获取已安装的包列表
async function loadInstalledPackages() {
  try {
    loading.value = true
    
    // 获取已安装的包信息（使用 local 函数避免污染全局环境）
    const code = `webr::shim_install()
local({
  installed_pkgs <- installed.packages()
  pkg_df <- data.frame(
    Package = rownames(installed_pkgs),
    Version = installed_pkgs[, "Version"],
    stringsAsFactors = FALSE
  )
  pkg_df
})`
    
    const result = await runR(code)
    if (result && result.result) {
      const pkgData = await result.result.toJs()
      
      // 调试：打印数据结构
      console.log('Package data structure:', pkgData)
      
      const pkgArray = []
      
      if (pkgData && typeof pkgData === 'object') {
        // WebR dataframe 是嵌套结构：{ names: [...], values: [{ values: [...] }, ...] }
        if (pkgData.names && Array.isArray(pkgData.names) && pkgData.values && Array.isArray(pkgData.values)) {
          // 嵌套结构：{ names: ['Package', 'Version'], values: [{ values: [...] }, { values: [...] }] }
          const names = pkgData.names || []
          const values = pkgData.values || []
          
          // 找到 Package 和 Version 列的索引
          const packageIndex = names.indexOf('Package')
          const versionIndex = names.indexOf('Version')
          
          if (packageIndex >= 0 && versionIndex >= 0 && values[packageIndex] && values[versionIndex]) {
            // 获取列数据，可能是 { values: [...] } 或直接是数组
            const packageCol = values[packageIndex]
            const versionCol = values[versionIndex]
            
            const packageValues = (packageCol.values && Array.isArray(packageCol.values)) 
              ? packageCol.values 
              : (Array.isArray(packageCol) ? packageCol : [])
            
            const versionValues = (versionCol.values && Array.isArray(versionCol.values)) 
              ? versionCol.values 
              : (Array.isArray(versionCol) ? versionCol : [])
            
            const maxLength = Math.max(packageValues.length, versionValues.length)
            
            for (let i = 0; i < maxLength; i++) {
              pkgArray.push({
                Package: String(packageValues[i] || ''),
                Version: String(versionValues[i] || '')
              })
            }
          }
        } else if (pkgData.Package && Array.isArray(pkgData.Package)) {
          // 简单列式数据：{ Package: [...], Version: [...] }
          const names = pkgData.Package || []
          const versions = pkgData.Version || []
          for (let i = 0; i < names.length; i++) {
            pkgArray.push({
              Package: String(names[i] || ''),
              Version: String(versions[i] || '')
            })
          }
        } else if (Array.isArray(pkgData)) {
          // 行式数组数据
          packages.value = pkgData.map(pkg => ({
            Package: String(pkg.Package || pkg[0] || ''),
            Version: String(pkg.Version || pkg[1] || '')
          }))
          webR.destroy(result)
          if (pkgData) webR.destroy(pkgData)
          return
        } else {
          // 尝试从对象中提取数据
          const keys = Object.keys(pkgData)
          for (const key of keys) {
            const item = pkgData[key]
            if (item && typeof item === 'object') {
              pkgArray.push({
                Package: String(item.Package || key || ''),
                Version: String(item.Version || '')
              })
            }
          }
        }
      }
      
      console.log('Parsed packages:', pkgArray)
      packages.value = pkgArray
      webR.destroy(result)
      if (pkgData) webR.destroy(pkgData)
    }
    
    // 获取已加载的包列表
    await loadLoadedPackages()
    
    loading.value = false
  } catch (error) {
    console.error('加载已安装包列表失败:', error)
    message.error(`加载包列表失败: ${error.message || '未知错误'}`)
    loading.value = false
  }
}

// 获取已加载的包列表
async function loadLoadedPackages() {
  try {
    // 使用 evalRString 直接获取字符串数组
    const code = `webr::shim_install(); paste(.packages(), collapse = ",")`
    const loadedStr = await webR.evalRString(code)
    
    if (loadedStr) {
      // 将逗号分隔的字符串转换为数组
      loadedPackages.value = loadedStr.split(',').map(pkg => pkg.trim()).filter(Boolean)
      console.log('已加载的包:', loadedPackages.value)
    } else {
      loadedPackages.value = []
    }
  } catch (error) {
    console.error('加载已加载包列表失败:', error)
    // 尝试备用方法
    try {
      const code = `.packages()`
      const result = await runR(code)
      if (result && result.result) {
        const loaded = await result.result.toJs()
        console.log('备用方法获取的数据:', loaded)
        
        let loadedArray = []
        if (Array.isArray(loaded)) {
          loadedArray = loaded
        } else if (loaded && typeof loaded === 'object') {
          // 如果是对象，尝试提取数组
          const keys = Object.keys(loaded)
          if (keys.length > 0 && Array.isArray(loaded[keys[0]])) {
            loadedArray = loaded[keys[0]]
          } else if (loaded.values && Array.isArray(loaded.values)) {
            // WebR 返回的可能是嵌套结构
            loadedArray = loaded.values.flatMap(v => 
              Array.isArray(v) ? v : (v.values ? v.values : [])
            )
          }
        }
        
        loadedPackages.value = loadedArray.map(pkg => String(pkg || '').trim()).filter(Boolean)
        console.log('备用方法解析结果:', loadedPackages.value)
        
        webR.destroy(result)
        if (loaded) webR.destroy(loaded)
      }
    } catch (fallbackError) {
      console.error('备用方法也失败:', fallbackError)
      loadedPackages.value = []
    }
  }
}

// 刷新包列表
async function refreshPackages() {
  await loadInstalledPackages()
  message.success('包列表已刷新')
}

// 切换包的加载状态
async function togglePackage(packageName, checked) {
  try {
    if (checked) {
      // 加载包
      const code = `library("${packageName}")`
      await webR.evalRVoid(code)
      message.success(`已加载包: ${packageName}`)
    } else {
      // 卸载包 - 尝试多种方式
      try {
        // 方法1: detach
        const code = `detach("package:${packageName}", unload = TRUE)`
        await webR.evalRVoid(code)
      } catch (detachError) {
        // 如果 detach 失败，尝试 unloadNamespace
        console.warn('detach 失败，尝试 unloadNamespace:', detachError)
        try {
          await webR.evalRVoid(`unloadNamespace("${packageName}")`)
        } catch (unloadError) {
          throw new Error(`无法卸载包 ${packageName}: ${detachError.message}`)
        }
      }
      message.success(`已卸载包: ${packageName}`)
    }
    
    // 等待一下，确保操作完成
    await new Promise(resolve => setTimeout(resolve, 100))
    
    // 刷新已加载的包列表
    await loadLoadedPackages()
  } catch (error) {
    console.error('切换包状态失败:', error)
    message.error(`操作失败: ${error.message || '未知错误'}`)
    // 即使失败也刷新列表
    await loadLoadedPackages()
  }
}

// 过滤包列表
const filteredPackages = computed(() => {
  let result = packages.value
  
  // 如果勾选了"只显示已加载的包"，先过滤已加载的包
  if (showLoadedOnly.value) {
    const loadedSet = new Set(loadedPackages.value)
    result = result.filter(pkg => loadedSet.has(pkg.Package))
  }
  
  // 如果有搜索文本，再进行搜索过滤
  if (searchText.value) {
    const search = searchText.value.toLowerCase()
    result = result.filter(pkg => 
      pkg.Package.toLowerCase().includes(search)
    )
  }
  
  return result
})

// 表格列定义
const columns = computed(() => [
  {
    title: '已加载',
    key: 'loaded',
    width: 80,
    render(row) {
      // 确保比较时使用字符串
      const packageName = String(row.Package || '')
      const isLoaded = loadedPackages.value.includes(packageName)
      return h(NCheckbox, {
        checked: isLoaded,
        onUpdateChecked: async (checked) => {
          await togglePackage(packageName, checked)
        }
      })
    }
  },
  {
    title: '包名',
    key: 'Package',
    width: 200,
    ellipsis: {
      tooltip: true
    }
  },
  {
    title: '版本',
    key: 'Version',
    width: 150,
    ellipsis: {
      tooltip: true
    }
  }
])

// 分页配置（使用 reactive 确保响应式）
const pagination = reactive({
  pageSize: 10,
  showSizePicker: true,
  pageSizes: [5, 10, 20, 50, 100],
  showQuickJumper: true,
  onUpdatePageSize: (size) => {
    pagination.pageSize = size
  }
})

onMounted(async () => {
  await waitForWebRInit()
  await loadInstalledPackages()
})
</script>

<style scoped>
.box {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 0 5px 5px 5px;
  box-sizing: border-box;
  overflow: hidden;
}

.toolbar {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  padding: 4px 12px;
  background-color: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(10px);
  flex-shrink: 0;
  transition: all 0.2s ease;
  align-items: center;
}

.table-container {
  flex: 1;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.table-container :deep(.n-data-table) {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.table-container :deep(.n-data-table-base-table) {
  flex: 1;
  overflow: auto;
}

.table-container :deep(.n-data-table-pagination) {
  flex-shrink: 0;
  margin-top: 0;
  padding: 8px 0;
}
</style>
