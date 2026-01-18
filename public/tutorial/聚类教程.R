# 聚类分析教程
# K-means, 层次聚类, DBSCAN等

# ===== 1. K-means聚类 =====
# 创建示例数据
set.seed(123)
x1 <- c(rnorm(50, 2, 0.5), rnorm(50, 6, 0.5), rnorm(50, 10, 0.5))
x2 <- c(rnorm(50, 2, 0.5), rnorm(50, 6, 0.5), rnorm(50, 2, 0.5))
data <- data.frame(x1, x2)

# 可视化原始数据
plot(data, pch = 19, col = "gray", main = "原始数据")

# K-means聚类（k=3）
kmeans_result <- kmeans(data, centers = 3, nstart = 25)

# 查看聚类结果
kmeans_result$cluster
kmeans_result$centers
kmeans_result$withinss  # 组内平方和
kmeans_result$totss     # 总平方和
kmeans_result$betweenss # 组间平方和

# 可视化聚类结果
plot(data, 
     col = kmeans_result$cluster + 1,
     pch = 19,
     main = "K-means聚类结果 (k=3)")
points(kmeans_result$centers, 
       col = 2:4, 
       pch = 8, 
       cex = 2, 
       lwd = 2)
legend("topright", 
       legend = paste("簇", 1:3),
       col = 2:4, 
       pch = 19)

# ===== 2. 确定最优聚类数 =====
# 使用肘部法则 (Elbow Method)
wss <- numeric(10)
for(k in 1:10) {
  kmeans_temp <- kmeans(data, centers = k, nstart = 25)
  wss[k] <- kmeans_temp$tot.withinss
}

plot(1:10, wss,
     type = "b",
     pch = 19,
     xlab = "聚类数 (k)",
     ylab = "组内平方和 (WSS)",
     main = "肘部法则：确定最优k值")

# 使用轮廓系数（需要cluster包）
# library(cluster)
# sil_width <- numeric(9)
# for(k in 2:10) {
#   kmeans_temp <- kmeans(data, centers = k, nstart = 25)
#   sil <- silhouette(kmeans_temp$cluster, dist(data))
#   sil_width[k-1] <- mean(sil[, 3])
# }
# plot(2:10, sil_width, type = "b", xlab = "k", ylab = "平均轮廓系数")

# ===== 3. 层次聚类 =====
# 计算距离矩阵
dist_matrix <- dist(data)

# 使用不同连接方法
hc_complete <- hclust(dist_matrix, method = "complete")
hc_average <- hclust(dist_matrix, method = "average")
hc_single <- hclust(dist_matrix, method = "single")

# 绘制树状图
par(mfrow = c(1, 3))
plot(hc_complete, main = "完全连接", xlab = "")
plot(hc_average, main = "平均连接", xlab = "")
plot(hc_single, main = "单连接", xlab = "")
par(mfrow = c(1, 1))

# 切分树得到3个簇
clusters_hc <- cutree(hc_complete, k = 3)

# 可视化层次聚类结果
plot(data,
     col = clusters_hc + 1,
     pch = 19,
     main = "层次聚类结果 (完全连接, k=3)")
legend("topright",
       legend = paste("簇", 1:3),
       col = 2:4,
       pch = 19)

# ===== 4. DBSCAN聚类 =====
# 需要dbscan包
# install.packages("dbscan")
# library(dbscan)

# 创建示例数据
set.seed(123)
x1 <- c(rnorm(100, 0, 0.3), rnorm(100, 3, 0.3), rnorm(20, 1.5, 0.1))
x2 <- c(rnorm(100, 0, 0.3), rnorm(100, 3, 0.3), rnorm(20, 1.5, 0.1))
data_dbscan <- data.frame(x1, x2)

# DBSCAN聚类
# dbscan_result <- dbscan(data_dbscan, eps = 0.5, minPts = 5)
# plot(data_dbscan, col = dbscan_result$cluster + 1, pch = 19)

# ===== 5. 聚类评估 =====
# 内部评估指标（如果知道真实标签）
# 创建已知标签的数据
set.seed(123)
true_labels <- rep(1:3, each = 50)
data_labeled <- data.frame(
  x1 = c(rnorm(50, 2, 0.5), rnorm(50, 6, 0.5), rnorm(50, 10, 0.5)),
  x2 = c(rnorm(50, 2, 0.5), rnorm(50, 6, 0.5), rnorm(50, 2, 0.5)),
  label = true_labels
)

# K-means聚类
kmeans_labeled <- kmeans(data_labeled[, 1:2], centers = 3, nstart = 25)

# 调整兰德指数 (Adjusted Rand Index)
# 需要mclust包
# library(mclust)
# adjustedRandIndex(true_labels, kmeans_labeled$cluster)

# ===== 6. 高维数据聚类 =====
# 创建高维数据
set.seed(123)
high_dim_data <- matrix(rnorm(300), ncol = 10)
high_dim_data[1:50, ] <- high_dim_data[1:50, ] + 2
high_dim_data[51:100, ] <- high_dim_data[51:100, ] + 5

# K-means聚类
kmeans_high <- kmeans(high_dim_data, centers = 3, nstart = 25)

# 使用PCA可视化高维聚类结果
pca_result <- prcomp(high_dim_data, scale. = TRUE)
plot(pca_result$x[, 1:2],
     col = kmeans_high$cluster + 1,
     pch = 19,
     main = "高维数据的PCA可视化（颜色表示聚类）")

# ===== 7. 混合模型聚类 =====
# 需要mclust包
# library(mclust)
# 
# mclust_result <- Mclust(data)
# summary(mclust_result)
# plot(mclust_result)

# ===== 8. 实际应用：客户细分 =====
# 创建模拟客户数据
set.seed(123)
customer_data <- data.frame(
  age = runif(200, 18, 65),
  annual_income = runif(200, 20000, 100000),
  spending_score = runif(200, 1, 100)
)

# 标准化数据
customer_scaled <- scale(customer_data)

# K-means聚类
customer_clusters <- kmeans(customer_scaled, centers = 4, nstart = 25)

# 添加聚类标签
customer_data$cluster <- customer_clusters$cluster

# 可视化（选择两个维度）
plot(customer_data$annual_income, 
     customer_data$spending_score,
     col = customer_data$cluster + 1,
     pch = 19,
     xlab = "年收入",
     ylab = "消费评分",
     main = "客户细分结果")
legend("topright",
       legend = paste("客户群", 1:4),
       col = 2:5,
       pch = 19)

# ===== 9. 聚类结果的解释 =====
# 分析每个簇的特征
for(i in 1:4) {
  cluster_data <- customer_data[customer_data$cluster == i, ]
  cat("\n簇", i, "的特征:\n")
  cat("  平均年龄:", mean(cluster_data$age), "\n")
  cat("  平均年收入:", mean(cluster_data$annual_income), "\n")
  cat("  平均消费评分:", mean(cluster_data$spending_score), "\n")
  cat("  样本数:", nrow(cluster_data), "\n")
}

# ===== 10. 处理不同尺度的变量 =====
# 如果不标准化，距离计算会被大尺度的变量主导
# 方法1：标准化
data_scaled <- scale(data)
kmeans_scaled <- kmeans(data_scaled, centers = 3, nstart = 25)

# 方法2：归一化到[0,1]
normalize <- function(x) {
  return((x - min(x)) / (max(x) - min(x)))
}
data_normalized <- as.data.frame(lapply(data, normalize))
kmeans_normalized <- kmeans(data_normalized, centers = 3, nstart = 25)

# ===== 11. 聚类稳定性 =====
# 多次运行K-means，检查结果的稳定性
set.seed(123)
n_runs <- 10
cluster_results <- matrix(0, nrow = nrow(data), ncol = n_runs)

for(i in 1:n_runs) {
  kmeans_run <- kmeans(data, centers = 3, nstart = 25)
  cluster_results[, i] <- kmeans_run$cluster
}

# 检查一致性（简化版本）
table(cluster_results[, 1], cluster_results[, 2])

# ===== 12. 可视化技巧 =====
# 使用不同的可视化方法
par(mfrow = c(2, 2))

# 原始数据
plot(data, pch = 19, col = "gray", main = "原始数据")

# K-means结果
plot(data, col = kmeans_result$cluster + 1, pch = 19, main = "K-means")
points(kmeans_result$centers, col = 2:4, pch = 8, cex = 2)

# 层次聚类结果
plot(data, col = clusters_hc + 1, pch = 19, main = "层次聚类")

# 簇的大小
barplot(table(kmeans_result$cluster),
        main = "各簇的样本数",
        xlab = "簇",
        ylab = "样本数",
        col = 2:4)

par(mfrow = c(1, 1))





