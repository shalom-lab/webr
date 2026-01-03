/**
 * WebR 工具函数
 * 提供公共的 WebR 操作函数，避免代码重复
 */

/**
 * 执行 R 代码
 * @param {Object} webR - WebR 实例
 * @param {string} code - R 代码
 * @param {Object} options - 执行选项
 * @returns {Promise<Object>} 执行结果
 */
export async function runRCode(webR, code, options = {}) {
  const shelter = await new webR.Shelter();
  try {
    // 自动添加 shim_install，确保兼容性
    const fullCode = options.skipShim ? code : `webr::shim_install() \n${code}`;
    
    const result = await shelter.captureR(fullCode, {
      withAutoprint: true,
      captureStreams: true,
      captureConditions: true,
      env: webR.objs.globalEnv,
      ...options
    });
    
    return result;
  } catch (error) {
    console.error('执行 R 代码时出错:', error);
    throw error;
  } finally {
    shelter.purge();
  }
}

/**
 * 格式化 R 输出消息
 * @param {Array} outputs - R 输出数组
 * @returns {Array} 格式化后的消息数组
 */
export function formatROutput(outputs) {
  if (!outputs || !Array.isArray(outputs)) {
    return [];
  }
  
  return outputs.map((output) => {
    let className = null;
    switch (output.type) {
      case 'stdout':
        className = '';
        break;
      case 'stderr':
        className = 'error';
        break;
      default:
        className = null;
    }
    return {
      type: 'normal',
      content: output.data,
      class: className
    };
  });
}

/**
 * 检查 WebR 是否已初始化
 * @param {Object} webR - WebR 实例
 * @returns {boolean} 是否已初始化
 */
export function isWebRInitialized(webR) {
  return webR && webR.objs && webR.objs.globalEnv;
}

/**
 * 安全地销毁 WebR 对象
 * @param {Object} webR - WebR 实例
 * @param {...Object} objects - 要销毁的对象
 */
export function safeDestroy(webR, ...objects) {
  objects.forEach(obj => {
    try {
      if (obj && webR && typeof webR.destroy === 'function') {
        webR.destroy(obj);
      }
    } catch (error) {
      console.warn('销毁对象时出错:', error);
    }
  });
}


