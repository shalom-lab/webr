<template>
    <n-tabs type="segment" animated pane-style="padding:0">
        <n-tab-pane name="chap1" tab="第一章">
            <n-scrollbar :style="{ height: innerHeight - 40 + 'px' }">
                <n-grid cols="1 200:2 400:2 600:3 800:4" :x-gap="8" :y-gap="8"
                    style="padding:8px;box-sizing:border-box">
                    <n-grid-item v-for="(item, index) in charts" :key="item.id">
                        <n-card hoverable content-style="padding:10px;border-radius:40px" class="zoomable">
                            <n-skeleton v-if="loading" text :repeat="9" />
                            <Canvas v-else :width="1000" :height="800" :imageBitmap="images[index][0]"></Canvas>
                        </n-card>
                    </n-grid-item>
                </n-grid>
            </n-scrollbar>
        </n-tab-pane>
        <n-tab-pane name="chap2" tab="第一章"></n-tab-pane>
        <n-tab-pane name="chap3" tab="第一章"></n-tab-pane>
        <n-tab-pane name="chap4" tab="第一章"></n-tab-pane>
    </n-tabs>
</template>

<script setup>
import Canvas from "@/components/Canvas.vue"
import { inject, onMounted } from 'vue'
import { useSize } from '@/use/size.js'
const { innerWidth, innerHeight } = useSize()

const loading = ref(true)
const charts = ref([
    {
        id: 1,
        name: '阳性率随月份变化的散点图',
        code: `
            library(tidyverse)
            set.seed(123)
            months <- rep(month.abb, each = 3)
            positivity_rate <- runif(36, 5, 20)
            data <- data.frame(months, positivity_rate)
            
            ggplot(data, aes(x = months, y = positivity_rate)) +
                geom_point(size = 3, color = "blue") +
                labs(title = "阳性率随月份的变化",
                     x = "月份",
                     y = "阳性率 (%)") +
                theme_bw() +
                theme(plot.title = element_text(hjust = 0.5, size = 20),
                      axis.title = element_text(size = 16),
                      axis.text = element_text(size = 12))
        `,
        tags: ['医学', '散点图']
    },
    {
        id: 2,
        name: '多组人群血压的箱线图',
        code: `
            library(tidyverse)
            set.seed(123)
            group <- rep(c("A组", "B组", "C组"), each = 50)
            blood_pressure <- c(rnorm(50, 120, 15), rnorm(50, 130, 15), rnorm(50, 125, 15))
            data <- data.frame(group, blood_pressure)
            
            ggplot(data, aes(x = group, y = blood_pressure)) +
                geom_boxplot(fill = "skyblue", color = "darkblue") +
                labs(title = "多组人群血压分布",
                     x = "组别",
                     y = "血压 (mmHg)") +
                theme_bw() +
                theme(plot.title = element_text(hjust = 0.5, size = 20),
                      axis.title = element_text(size = 16),
                      axis.text = element_text(size = 12))
        `,
        tags: ['医学', '箱线图']
    },
    {
        id: 3,
        name: '治疗前后血压的直方图',
        code: `
            library(tidyverse)
            set.seed(123)
            before <- rnorm(100, 150, 20)
            after <- rnorm(100, 135, 15)
            data <- data.frame(
                value = c(before, after),
                group = rep(c("治疗前", "治疗后"), each = 100)
            )
            
            ggplot(data, aes(x = value, fill = group)) +
                geom_histogram(position = "dodge", bins = 20, color = "black") +
                labs(title = "治疗前后血压分布",
                     x = "血压 (mmHg)",
                     y = "频数") +
                theme_bw() +
                theme(plot.title = element_text(hjust = 0.5, size = 20),
                      axis.title = element_text(size = 16),
                      axis.text = element_text(size = 12),
                      legend.title = element_text(size = 14),
                      legend.text = element_text(size = 12))
        `,
        tags: ['医学', '直方图']
    },
    {
        id: 4,
        name: '治疗前后血压的条形图',
        code: `
            library(tidyverse)
            set.seed(123)
            treatment <- rep(c("治疗前", "治疗后"), each = 100)
            blood_pressure <- c(rnorm(100, 150, 20), rnorm(100, 135, 15))
            data <- data.frame(treatment, blood_pressure)
            
            ggplot(data, aes(x = treatment, y = blood_pressure)) +
                geom_bar(stat = "summary", fun = "mean", fill = "lightgreen", color = "black") +
                labs(title = "治疗前后血压均值",
                     x = "治疗阶段",
                     y = "平均血压 (mmHg)") +
                theme_bw() +
                theme(plot.title = element_text(hjust = 0.5, size = 20),
                      axis.title = element_text(size = 16),
                      axis.text = element_text(size = 12))
        `,
        tags: ['医学', '条形图']
    },
    {
        id: 5,
        name: '治疗前后血压的线性回归',
        code: `
            library(tidyverse)
            set.seed(123)
            before <- rnorm(100, 150, 20)
            after <- rnorm(100, 135, 15)
            data <- data.frame(before, after)
            
            ggplot(data, aes(x = before, y = after)) +
                geom_point(size = 3, color = "red") +
                geom_smooth(method = "lm", se = FALSE, color = "blue") +
                labs(title = "治疗前后血压的线性回归",
                     x = "治疗前血压 (mmHg)",
                     y = "治疗后血压 (mmHg)") +
                theme_bw() +
                theme(plot.title = element_text(hjust = 0.5, size = 20),
                      axis.title = element_text(size = 16),
                      axis.text = element_text(size = 12))
        `,
        tags: ['医学', '线性回归']
    },
    {
        id: 6,
        name: '不同组别阳性率的饼图',
        code: `
            library(tidyverse)
            set.seed(123)
            groups <- c("A组", "B组", "C组")
            counts <- c(30, 45, 25)
            data <- data.frame(groups, counts)
            
            ggplot(data, aes(x = "", y = counts, fill = groups)) +
                geom_bar(stat = "identity", width = 1) +
                coord_polar(theta = "y") +
                labs(title = "不同组别的阳性率分布",
                     fill = "组别") +
                theme_bw() +
                theme(plot.title = element_text(hjust = 0.5, size = 20),
                      legend.title = element_text(size = 14),
                      legend.text = element_text(size = 12))
        `,
        tags: ['医学', '饼图']
    },
    {
        id: 7,
        name: '多组人群血压的小提琴图',
        code: `
            library(tidyverse)
            set.seed(123)
            group <- rep(c("A组", "B组", "C组"), each = 50)
            blood_pressure <- c(rnorm(50, 120, 15), rnorm(50, 130, 15), rnorm(50, 125, 15))
            data <- data.frame(group, blood_pressure)
            
            ggplot(data, aes(x = group, y = blood_pressure)) +
                geom_violin(fill = "lightblue", color = "black") +
                labs(title = "多组人群血压分布",
                     x = "组别",
                     y = "血压 (mmHg)") +
                theme_bw() +
                theme(plot.title = element_text(hjust = 0.5, size = 20),
                      axis.title = element_text(size = 16),
                      axis.text = element_text(size = 12))
        `,
        tags: ['医学', '小提琴图']
    }
])



const images = ref([])

const webR = inject('webR')

onMounted(async () => {
    const promiseArr = charts.value.map(async (item) => {
        const shelter = await new webR.Shelter();
        const capture = await shelter.captureR(item.code, {
            withAutoprint: true,
            captureStreams: true,
            captureConditions: true,
            env: webR.objs.globalEnv
        });
        return capture.images
    })
    images.value = await Promise.all(promiseArr)
    loading.value = false
})

</script>

<style scoped>
.zoomable {
    transition: transform 0.3s ease-in-out;
    cursor: pointer;
}

.zoomable:hover {
    transform: scale(1.05);
    /* 放大1.1倍，可以根据需要调整 */
    z-index: 1000;
    /* 确保放大的 card 在最上层 */
}
</style>