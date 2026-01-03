/**
 * Service Worker 缓存管理工具
 * 用于查看和管理 WebR 相关资源的缓存
 */

/**
 * 获取所有缓存名称
 */
export async function getCacheNames() {
  if (!('caches' in window)) {
    return []
  }
  return await caches.keys()
}

/**
 * 获取指定缓存的详细信息
 * @param {string} cacheName - 缓存名称
 * @returns {Promise<Object>} 缓存信息对象
 */
export async function getCacheInfo(cacheName) {
  if (!('caches' in window)) {
    return null
  }

  try {
    const cache = await caches.open(cacheName)
    const keys = await cache.keys()
    const requests = keys.map(key => ({
      url: key.url,
      method: key.method,
      headers: Object.fromEntries(key.headers.entries())
    }))

    // 计算总大小（近似值）
    let totalSize = 0
    for (const key of keys) {
      try {
        // cache.match() 可以接受 Request 对象或 URL 字符串
        // 优先使用 URL 字符串，更可靠
        const url = key.url || (key instanceof Request ? key.url : String(key))
        const response = await cache.match(url)
        if (response && response.ok) {
          const blob = await response.blob()
          totalSize += blob.size
        }
      } catch (error) {
        // 如果单个请求失败，继续处理其他请求
        // 不抛出错误，只记录警告
        console.warn(`Failed to get size for cache entry:`, error)
      }
    }

    return {
      name: cacheName,
      count: keys.length,
      size: totalSize,
      sizeFormatted: formatBytes(totalSize),
      requests: requests
    }
  } catch (error) {
    console.error(`Error getting cache info for ${cacheName}:`, error)
    return null
  }
}

/**
 * 获取所有 WebR 相关缓存的信息
 */
export async function getAllWebRCacheInfo() {
  const cacheNames = await getCacheNames()
  const webrCaches = cacheNames.filter(name => 
    name.includes('R-') || 
    name.includes('r-wasm') || 
    name.includes('webr') || 
    name.includes('library')
  )

  const cacheInfos = await Promise.all(
    webrCaches.map(name => getCacheInfo(name))
  )

  return cacheInfos.filter(info => info !== null)
}

/**
 * 清除指定的缓存
 * @param {string} cacheName - 缓存名称
 */
export async function clearCache(cacheName) {
  if (!('caches' in window)) {
    return false
  }

  try {
    return await caches.delete(cacheName)
  } catch (error) {
    console.error(`Error clearing cache ${cacheName}:`, error)
    return false
  }
}

/**
 * 清除所有 WebR 相关缓存
 */
export async function clearAllWebRCaches() {
  const cacheNames = await getCacheNames()
  const webrCaches = cacheNames.filter(name => 
    name.includes('R-') || 
    name.includes('r-wasm') || 
    name.includes('webr') || 
    name.includes('library')
  )

  const results = await Promise.all(
    webrCaches.map(name => clearCache(name))
  )

  return results.every(result => result === true)
}

/**
 * 格式化字节大小
 * @param {number} bytes - 字节数
 * @returns {string} 格式化后的字符串
 */
function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

/**
 * 检查 Service Worker 是否已注册
 */
export async function checkServiceWorkerStatus() {
  if (!('serviceWorker' in navigator)) {
    return {
      supported: false,
      registered: false,
      message: '浏览器不支持 Service Worker'
    }
  }

  try {
    const registrations = await navigator.serviceWorker.getRegistrations()
    return {
      supported: true,
      registered: registrations.length > 0,
      count: registrations.length,
      registrations: registrations.map(reg => ({
        scope: reg.scope,
        active: reg.active !== null,
        installing: reg.installing !== null,
        waiting: reg.waiting !== null
      }))
    }
  } catch (error) {
    return {
      supported: true,
      registered: false,
      error: error.message
    }
  }
}

