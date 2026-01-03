/**
 * WebR 初始化配置
 * 管理 WebR 初始化相关的 R 代码和包安装
 */

// tidyverse 核心包列表（分别安装，不直接安装 tidyverse 元包）
export const TIDYVERSE_PACKAGES = [
  'ggplot2',      // 数据可视化
  'dplyr',        // 数据操作
  'tidyr',        // 数据整理
  'readr',        // 读取数据
  'purrr',        // 函数式编程
  'tibble',       // 现代数据框
  'stringr',      // 字符串处理
  'forcats'       // 因子处理
]

// 其他常用R包（用于教程和数据分析）
export const ADDITIONAL_PACKAGES = [
  'survival',     // 生存分析核心包
  'survminer'     // 生存分析可视化（如果可用）
]

/**
 * 生成初始化 R 代码
 * @returns {string} R 初始化代码
 */
export function getInitRCode() {
  return `
# 挂载库文件系统
webr::mount(mountpoint = "/home/library", source = "https://webr-1257749604.cos.ap-shanghai.myqcloud.com/vfs/library.data")

# 设置库路径
.libPaths(c("/home/library", .libPaths()))

# 安装 shim
webr::shim_install()
`
}

/**
 * 生成包安装 R 代码（静默安装）
 * @param {string[]} packages - 要安装的包名列表
 * @returns {string} 包安装 R 代码
 */
export function getPackageInstallCode(packages) {
  if (!packages || packages.length === 0) {
    return ''
  }

  // 检查已安装的包，只安装未安装的包（使用 local 函数避免污染全局环境）
  return `local({
  packages_to_install <- ${JSON.stringify(packages)}
  installed_packages <- rownames(installed.packages())
  missing_packages <- setdiff(packages_to_install, installed_packages)
  
  if (length(missing_packages) > 0) {
    for (pkg in missing_packages) {
      tryCatch({
        webr::install(pkg, repos = NULL, quiet = TRUE)
        cat("已安装:", pkg, "\\n")
      }, error = function(e) {
        cat("安装失败:", pkg, "-", conditionMessage(e), "\\n")
      })
    }
  } else {
    cat("所有包已安装\\n")
  }
})`
}

/**
 * 获取完整的初始化代码（包含包安装）
 * @param {string[]} packagesToInstall - 需要安装的包列表（可选）
 * @returns {string} 完整的初始化代码
 */
export function getFullInitCode(packagesToInstall = []) {
  const initCode = getInitRCode()
  const installCode = packagesToInstall.length > 0 
    ? getPackageInstallCode(packagesToInstall)
    : ''
  
  return initCode + '\n' + installCode
}

/**
 * 执行 WebR 初始化
 * @param {Object} webR - WebR 实例
 * @param {Object} options - 初始化选项
 * @param {string[]} options.packagesToInstall - 要安装的包列表
 * @param {Function} options.onProgress - 进度回调函数
 * @returns {Promise<void>}
 */
export async function initWebR(webR, options = {}) {
  const {
    packagesToInstall = [],
    onProgress
  } = options

  try {
    // 1. 执行基础初始化
    if (onProgress) onProgress('正在挂载文件系统...')
    await webR.evalRVoid('webr::mount(mountpoint = "/home/library", source = "https://webr-1257749604.cos.ap-shanghai.myqcloud.com/vfs/library.data")')
    
    if (onProgress) onProgress('正在设置库路径...')
    await webR.evalR('.libPaths(c("/home/library", .libPaths()))')
    
    if (onProgress) onProgress('正在安装 shim...')
    await webR.evalRVoid('webr::shim_install()')

    // 2. 安装包（如果有指定）
    if (packagesToInstall.length > 0) {
      if (onProgress) onProgress(`正在检查并安装 ${packagesToInstall.length} 个包...`)
      
      // 使用 R 代码批量检查并安装（使用 local 函数避免污染全局环境）
      const packagesList = packagesToInstall.map(p => `"${p}"`).join(', ')
      const installCode = `local({
  packages_to_install <- c(${packagesList})
  installed_packages <- rownames(installed.packages())
  missing_packages <- setdiff(packages_to_install, installed_packages)
  
  if (length(missing_packages) > 0) {
    for (pkg in missing_packages) {
      tryCatch({
        webr::install(pkg, repos = NULL, quiet = TRUE)
        cat("已安装:", pkg, "\\n")
      }, error = function(e) {
        cat("安装失败:", pkg, "-", conditionMessage(e), "\\n")
      })
    }
  } else {
    cat("所有包已安装\\n")
  }
})`
      // 静默执行安装代码（不捕获输出）
      try {
        await webR.evalRVoid(installCode)
        console.log('包安装完成')
      } catch (error) {
        console.warn('部分包安装可能失败:', error.message)
        // 继续执行，不中断初始化流程
      }
    }

    // 3. 创建示例代码文件
    if (onProgress) onProgress('正在创建示例文件...')
    const demoCode = `demo(graphics)
a<-1:10
b<-mtcars
d<-list(c=4)
e<-function(x){x}
f<-3
m<-matrix(1:100)
`
    const data = new TextEncoder().encode(demoCode)
    await webR.FS.writeFile('/home/web_user/code.R', data)

    // 4. 加载 tutorial 文件
    await loadTutorialFiles(webR, onProgress)

  } catch (error) {
    console.error('WebR 初始化失败:', error)
    throw error
  }
}

/**
 * 加载 tutorial 文件夹中的教学文件到 WebR 文件系统
 * @param {Object} webR - WebR 实例
 * @param {Function} onProgress - 进度回调函数（可选）
 * @returns {Promise<void>}
 */
export async function loadTutorialFiles(webR, onProgress) {
  try {
    if (onProgress) onProgress('正在加载教程文件...')
    
    // 创建 tutorial 目录
    try {
      await webR.FS.mkdir('/home/web_user/tutorial')
    } catch (error) {
      // 如果目录已存在，忽略错误
      if (!error.message.includes('File exists')) {
        throw error
      }
    }

    // tutorial 文件列表 - 使用循环处理所有文件
    const tutorialFiles = [
      '基本数据类型.R',
      '函数.R',
      '数据框.R',
      '基础R包作图系列.R',
      'ggplot_tidyverse教程.R',
      'lm回归教程.R',
      'logistic回归教程.R',
      '聚类教程.R',
      '字符串处理系列.R',
      '正则表达式系列.R',
      '向量化思维系列.R',
      '生存分析教程.R'
    ]

    // 读取并写入每个文件
    for (const fileName of tutorialFiles) {
      try {
        // 从 public/tutorial 目录读取文件
        // 使用 import.meta.env.BASE_URL 来适配 GitHub Pages 的 base 路径
        const baseUrl = import.meta.env.BASE_URL || '/'
        const tutorialPath = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl
        const response = await fetch(`${tutorialPath}/tutorial/${encodeURIComponent(fileName)}`)
        
        if (!response.ok) {
          console.warn(`无法加载教程文件: ${fileName} (${response.status})`)
          continue
        }

        // 读取文件内容
        const arrayBuffer = await response.arrayBuffer()
        const uint8Array = new Uint8Array(arrayBuffer)
        
        // 写入到 WebR 文件系统
        const filePath = `/home/web_user/tutorial/${fileName}`
        await webR.FS.writeFile(filePath, uint8Array)
        
        console.log(`已加载教程文件: ${fileName}`)
      } catch (error) {
        console.warn(`加载教程文件失败: ${fileName}`, error)
        // 继续加载其他文件，不中断流程
      }
    }

    if (onProgress) onProgress('教程文件加载完成')
  } catch (error) {
    console.error('加载教程文件时出错:', error)
    // 不抛出错误，避免影响主初始化流程
  }
}

