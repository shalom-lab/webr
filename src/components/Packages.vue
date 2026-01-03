<template>
  <div class="box">
    <n-space justify="space-between" class="toolbar">
      <n-space>
        <n-button text @click="refreshPackages">
          <n-icon size="20" :component="RefreshOutlined" />
        </n-button>
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
import { ref, computed, inject, onMounted, h } from 'vue'
import { NDataTable, NCheckbox, NIcon, NButton, NInput, NSpace, NEmpty, useMessage } from 'naive-ui'
import { RefreshOutlined } from '@vicons/material'

const webR = inject('webR')
const message = useMessage()

const packages = ref([])
const loadedPackages = ref([])
const loading = ref(false)
const searchText = ref('')

// 等待 WebR 初始化完成
async function waitForWebRInit() {
  if (webR.objs && webR.objs.globalEnv) {
    return
  }
  
  const maxWait = 10000
  const interval = 100
  const startTime = Date.now()
  
  while (Date.now() - startTime < maxWait) {
    if (webR.objs && webR.objs.globalEnv) {
      return
    }
    await new Promise(resolve => setTimeout(resolve, interval))
  }
  
  throw new Error('WebR 初始化超时')
}

// 执行 R 代码
async function runR(code) {
  try {
    if (!webR.objs || !webR.objs.globalEnv) {
      throw new Error('WebR 尚未初始化')
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
    
    // 获取已安装的包信息
    const code = `
      webr::shim_install()
      installed_pkgs <- installed.packages()
      # 转换为 dataframe，只保留 Package 和 Version 列
      pkg_df <- data.frame(
        Package = rownames(installed_pkgs),
        Version = installed_pkgs[, "Version"],
        stringsAsFactors = FALSE
      )
      pkg_df
    `
    
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
    const code = `
      webr::shim_install()
      .packages()
    `
    
    const result = await runR(code)
    if (result && result.result) {
      const loaded = await result.result.toJs()
      
      if (Array.isArray(loaded)) {
        loadedPackages.value = loaded
      } else if (loaded && typeof loaded === 'object') {
        // 如果是对象，尝试提取数组
        const keys = Object.keys(loaded)
        if (keys.length > 0 && Array.isArray(loaded[keys[0]])) {
          loadedPackages.value = loaded[keys[0]]
        } else {
          loadedPackages.value = []
        }
      } else {
        loadedPackages.value = []
      }
      
      webR.destroy(result)
      if (loaded) webR.destroy(loaded)
    }
  } catch (error) {
    console.error('加载已加载包列表失败:', error)
    loadedPackages.value = []
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
      const code = `library("${packageName}", character.only = TRUE)`
      await runR(code)
      message.success(`已加载包: ${packageName}`)
    } else {
      // 卸载包 - 使用字符串形式更安全
      const code = `detach("package:${packageName}", unload = TRUE)`
      await runR(code)
      message.success(`已卸载包: ${packageName}`)
    }
    
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
  if (!searchText.value) {
    return packages.value
  }
  const search = searchText.value.toLowerCase()
  return packages.value.filter(pkg => 
    pkg.Package.toLowerCase().includes(search)
  )
})

// 表格列定义
const columns = computed(() => [
  {
    title: '已加载',
    key: 'loaded',
    width: 80,
    render(row) {
      const isLoaded = loadedPackages.value.includes(row.Package)
      return h(NCheckbox, {
        checked: isLoaded,
        onUpdateChecked: (checked) => {
          togglePackage(row.Package, checked)
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

// 分页配置
const pagination = {
  pageSize: 10,
  showSizePicker: true,
  pageSizes: [5, 10, 20, 50, 100],
  showQuickJumper: true
}

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
  padding: 5px;
  box-sizing: border-box;
  overflow: hidden;
}

.toolbar {
  border-bottom: 1px solid #f3f3f356;
  padding: 2px 5px;
  flex-shrink: 0;
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
