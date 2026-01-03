# WebR 缓存优化说明

## 概述

本项目已实现基于 Service Worker 的缓存机制，用于缓存 WebR 相关的资源文件，包括：
- R 核心文件（R.bin.data, R.bin.js, R.bin.wasm）
- R 包文件（.tar.gz）
- WebR 数据文件（.data, .metadata）
- 其他 WebR 资源文件

## 缓存策略优化

### 1. 主要改进

#### 之前的问题
- `webr.r-wasm.org` 使用 `NetworkFirst` 策略，每次都会先尝试网络请求
- 如果网络较慢，用户需要等待较长时间
- R 包文件没有专门的缓存规则

#### 优化后的策略
- **CacheFirst 策略**：优先使用缓存，如果缓存不存在或过期才从网络获取
- **更长的缓存时间**：30 天（2,592,000 秒）
- **更大的缓存容量**：支持缓存更多 R 包（最多 500 个条目）
- **专门的 R 包缓存**：为 `.tar.gz` 文件添加专门的缓存规则

### 2. 缓存规则详情

| 缓存名称 | URL 模式 | 策略 | 最大条目 | 过期时间 |
|---------|---------|------|---------|---------|
| R-bin-cache | `R.bin.(data\|js\|wasm)` | CacheFirst | 100 | 30 天 |
| r-wasm-cache | `https://webr.r-wasm.org/*` | CacheFirst | 500 | 30 天 |
| r-packages-cache | `*.tar.gz` | CacheFirst | 200 | 30 天 |
| webr-data-cache | `*.data` | CacheFirst | 200 | 30 天 |
| webr-metadata-cache | `*.metadata` | CacheFirst | 200 | 30 天 |
| library-data-cache | 腾讯云 COS 库文件 | CacheFirst | 100 | 30 天 |
| library-metadata-cache | 腾讯云 COS 元数据 | CacheFirst | 100 | 30 天 |
| webr-assets-cache | `*.wasm`, `*.js.map` | CacheFirst | 100 | 30 天 |

## 工作原理

### Service Worker 缓存流程

1. **首次访问**
   - Service Worker 注册并激活
   - 用户访问应用时，WebR 资源从网络下载
   - 下载的资源自动缓存到浏览器

2. **后续访问**
   - Service Worker 拦截资源请求
   - 优先从缓存中获取资源
   - 如果缓存命中，立即返回（快速加载）
   - 如果缓存未命中，从网络获取并更新缓存

3. **缓存更新**
   - 缓存过期后，从网络获取最新版本
   - 新版本自动更新到缓存

## 使用方法

### 查看缓存状态

项目提供了缓存管理组件 `CacheManager.vue`，可以：

1. **查看 Service Worker 状态**
   - 检查浏览器是否支持 Service Worker
   - 检查 Service Worker 是否已注册

2. **查看缓存信息**
   - 查看所有 WebR 相关缓存
   - 查看每个缓存的条目数和大小
   - 查看总缓存统计

3. **管理缓存**
   - 清除单个缓存
   - 清除所有 WebR 缓存

### 在代码中使用

```javascript
import { 
  getAllWebRCacheInfo, 
  clearAllWebRCaches,
  checkServiceWorkerStatus 
} from '@/use/cache'

// 获取所有缓存信息
const cacheInfos = await getAllWebRCacheInfo()

// 检查 Service Worker 状态
const status = await checkServiceWorkerStatus()

// 清空所有缓存
await clearAllWebRCaches()
```

## 性能提升

### 预期效果

- **首次加载**：需要下载所有资源（与之前相同）
- **后续加载**：
  - R 核心文件：从缓存加载，速度提升 **90%+**
  - R 包文件：从缓存加载，速度提升 **95%+**
  - 整体加载时间：从数秒减少到毫秒级

### 实际测试建议

1. 首次访问应用，记录加载时间
2. 刷新页面，记录加载时间
3. 关闭浏览器后重新打开，记录加载时间
4. 对比三次加载时间的差异

## 注意事项

### 1. HTTPS 要求
Service Worker 必须在 HTTPS 环境下运行（localhost 除外）

### 2. 浏览器兼容性
- Chrome/Edge: 完全支持
- Firefox: 完全支持
- Safari: iOS 11.3+ 支持
- 移动浏览器: 大多数现代浏览器支持

### 3. 缓存更新
- 缓存会在 30 天后自动过期
- 如果需要强制更新，可以清空缓存
- 应用更新时，Service Worker 会自动更新

### 4. 存储空间
- 浏览器可能会限制 Service Worker 缓存大小
- 如果缓存过大，浏览器可能会自动清理旧缓存
- 建议定期检查缓存使用情况

## 故障排除

### Service Worker 未注册
1. 检查浏览器是否支持 Service Worker
2. 检查是否在 HTTPS 环境下（或 localhost）
3. 检查浏览器控制台是否有错误信息

### 缓存未生效
1. 检查 Service Worker 是否正常运行
2. 检查浏览器开发者工具中的 Application > Cache Storage
3. 尝试清除缓存后重新访问

### 缓存占用空间过大
1. 使用 `CacheManager` 组件查看缓存大小
2. 如果过大，可以手动清除不需要的缓存
3. 调整 `vite.config.js` 中的 `maxEntries` 参数

## 相关资源

- [WebR 官方文档](https://docs.r-wasm.org/webr/latest/)
- [Service Worker API](https://developer.mozilla.org/zh-CN/docs/Web/API/Service_Worker_API)
- [Workbox 文档](https://developers.google.com/web/tools/workbox)

## 更新日志

### 2024-01-XX
- 优化缓存策略，将 `webr.r-wasm.org` 从 NetworkFirst 改为 CacheFirst
- 添加 R 包文件（.tar.gz）的专门缓存规则
- 增加缓存容量，支持更多 R 包
- 添加缓存管理工具和 UI 组件


