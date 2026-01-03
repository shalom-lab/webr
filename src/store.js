import { createStore } from 'vuex'

const get_ls = `webr_objs<-ls()

# 过滤掉内部使用的变量：webr_ 前缀和 _WEBR_ 前缀
webr_objs<-webr_objs[!grepl('^webr_',webr_objs) & !grepl('^_WEBR_',webr_objs)]

webr_dfs<-Filter(function(x) is.data.frame(get(x)),webr_objs)
webr_fns<-Filter(function(x) is.function(get(x)),webr_objs)
webr_lis<-Filter(function(x) is.list(get(x)),webr_objs)
webr_mts<-Filter(function(x) is.matrix(get(x)),webr_objs)

lapply(webr_objs, function(x){
  if(x %in% webr_dfs){
    return(list(x,'dataframe',dim(get(x))[1],dim(get(x))[2],sapply(names(get(x)), function(y){
        paste0(head(get(x)[[y]]),collapse = ',')
      }),sapply(get(x), class)))
  } else if (x %in% webr_lis) {
    return(list(x,'list',length(get(x))))
  } else if (x %in% webr_fns) {
    return(list(x,'function'))
  } else if (x %in% webr_mts) {
    return(list(x,'matrix',dim(get(x))[1],dim(get(x))[2]))
  } else {
    return(list(x,'other',mode(get(x)),length(get(x)),paste(head(get(x)),collapse=',')))
  }
})
`


const store = createStore({
    state() {
        return {
            images: [],
            dataframes: [],
            fileList: null,
            filesOpen: [],
            dfsOpen: [],
            activeTabPane: null,
            activePanel: 'files',
            activePlot: null,
            objs: null,
            code: { get_ls },
            settings: {
                darkMode: false,
                topTabs: ['env'], // 右上显示的 tab 列表
                bottomTabs: ['files', 'plots', 'packages', 'cache'] // 右下显示的 tab 列表
            }
        }
    },
    getters: {
        get_dfs(state) {
            if (state.objs)
                return state.objs.values.filter((item) => item.values[1].values[0] == 'dataframe').map(
                    item => {
                        return {
                            name: item.values[0].values[0],
                            type: item.values[1].values[0],
                            nrow: item.values[2].values[0],
                            ncol: item.values[3].values[0],
                            names: item.values[4].names,
                            heads: item.values[4].values,
                            classes: item.values[5].values
                        }
                    })
        },
        get_mts(state) {
            if (state.objs)
                return state.objs.values.filter((item) => item.values[1].values[0] == 'matrix').map(
                    item => {
                        return {
                            name: item.values[0].values[0],
                            type: item.values[1].values[0],
                            nrow: item.values[2].values[0],
                            ncol: item.values[3].values[0]
                        }
                    })
        },
        get_lis(state) {
            if (state.objs)
                return state.objs.values.filter((item) => item.values[1].values[0] == 'list').map(
                    item => {
                        return {
                            name: item.values[0].values[0],
                            type: item.values[1].values[0],
                            length: item.values[2].values[0]
                        }
                    })
        },
        get_fns(state) {
            if (state.objs)
                return state.objs.values.filter((item) => item.values[1].values[0] == 'function').map(
                    item => {
                        return {
                            name: item.values[0].values[0],
                            type: item.values[1].values[0]
                        }
                    })
        },
        get_ots(state) {
            if (state.objs)
                return state.objs.values.filter((item) => item.values[1].values[0] == 'other').map(
                    item => {
                        return {
                            name: item.values[0].values[0],
                            type: item.values[1].values[0],
                            mode: item.values[2].values[0],
                            length: item.values[3].values[0],
                            head: item.values[4].values[0]
                        }
                    })
        },
        dfs(state) {
            var dfs = state.dataframes
            return Object.keys(dfs).map((item) => {
                return {
                    name: item,
                    nrow: dfs[item].names.length,
                    ncol: dfs[item].values[0].values.length,
                    data: dfs[item].values[0].values.map((item2, row_index) => {
                        let obj = {}
                        dfs[item].names.forEach((key, col_index) => {
                            obj[key] = dfs[item].values[col_index].values[row_index]
                        });
                        return obj
                    })
                }
            })
        },
        imagesList(state) {
            return state.images.map((item, index) => {
                return { id: index, data: item }
            })
        }
    },
    mutations: {
        addImages(state, payload) {
            payload.images.forEach(item => {
                state.images.push(item)
            })
            if (state.images.length > 0 && payload.images.length > 0) {
                state.activePlot = state.images.length - 1
            }
        },
        clearImages(state) {
            state.images = []
            state.activePlot = null
        },
        updateDataframes(state, payload) {
            state.dataframes = payload.dataframes
        },
        updateFileList(state, payload) {
            state.fileList = payload.fileList
        },
        pushFilesOpen(state, payload) {
            if (!state.filesOpen.includes(payload.fileName)) {
                state.filesOpen.push(payload.fileName)
            }
        },
        removeFilesOpen(state, payload) {
            state.filesOpen = state.filesOpen.filter(item => item != payload.fileName)
            if (!state.filesOpen.includes(state.activeTabPane) && state.filesOpen.length > 0) {
                state.activeTabPane = state.filesOpen.reverse()[0]
            }
        },
        //dfs_open
        pushDfsOpen(state, payload) {
            if (!state.dfsOpen.includes(payload.dfName)) {
                state.dfsOpen.push(payload.dfName)
            }
        },
        removeDfsOpen(state, payload) {
            state.dfsOpen = state.dfsOpen.filter(item => item != payload.dfName)
        },
        updateActiveTabPane(state, payload) {
            state.activeTabPane = payload.activeTabPane
        },
        updateActivePanel(state, payload) {
            state.activePanel = payload.activePanel
        },
        updateActivePlot(state, payload) {
            state.activePlot = payload.activePlot
        },
        updateObjs(state, payload) {
            state.objs = payload.objs
        },
        updateSettings(state, payload) {
            state.settings = { ...state.settings, ...payload }
        }
    }
})

export default store