# 向量化思维系列教程
# R的向量化操作和思维模式

# ===== 1. 什么是向量化 =====
# R的核心思想：向量化操作，避免循环

# 传统循环方式（不推荐）
x <- 1:1000000
result_loop <- numeric(length(x))
for(i in 1:length(x)) {
  result_loop[i] <- x[i] * 2
}

# 向量化方式（推荐，速度快得多）
result_vectorized <- x * 2

# 性能对比（在R中，向量化操作快几个数量级）
# system.time() 可以测量执行时间

# ===== 2. 基础向量化操作 =====
# 数学运算自动向量化
x <- 1:10
x * 2                              # 每个元素乘以2
x + 10                             # 每个元素加10
x ^ 2                              # 每个元素的平方
sqrt(x)                            # 每个元素的平方根

# 向量与向量运算（按元素）
x <- 1:5
y <- 6:10
x + y                              # 对应元素相加
x * y                              # 对应元素相乘
x / y                              # 对应元素相除

# ===== 3. 逻辑运算的向量化 =====
x <- 1:10
x > 5                              # 返回逻辑向量
x[x > 5]                           # 条件筛选
x[x %% 2 == 0]                     # 筛选偶数

# 多个条件
x[x > 3 & x < 8]                   # 同时满足两个条件
x[x < 3 | x > 8]                   # 满足任一条件

# ===== 4. 向量化函数 =====
# 大多数R函数都是向量化的
x <- c(1, 2, 3, 4, 5)
sqrt(x)                            # 向量化
log(x)                             # 向量化
exp(x)                             # 向量化
sin(x)                             # 向量化
abs(x)                             # 向量化

# ===== 5. 条件向量化：ifelse() =====
x <- 1:10
# 传统方式（不推荐）
result <- numeric(length(x))
for(i in 1:length(x)) {
  if(x[i] > 5) {
    result[i] <- x[i] * 2
  } else {
    result[i] <- x[i]
  }
}

# 向量化方式（推荐）
result <- ifelse(x > 5, x * 2, x)

# 更复杂的条件
x <- -5:5
ifelse(x > 0, "正数", ifelse(x < 0, "负数", "零"))

# ===== 6. apply族函数 =====
# 创建矩阵
mat <- matrix(1:12, nrow = 3, ncol = 4)

# apply() - 对矩阵的行或列应用函数
apply(mat, 1, sum)                 # 对每行求和
apply(mat, 2, sum)                 # 对每列求和
apply(mat, 1, mean)                # 对每行求均值

# lapply() - 对列表的每个元素应用函数
lst <- list(a = 1:5, b = 6:10, c = 11:15)
lapply(lst, sum)                   # 返回列表
sapply(lst, sum)                   # 返回向量（简化版本）

# vapply() - 指定返回类型，更安全
vapply(lst, sum, numeric(1))

# mapply() - 多参数版本
mapply(rep, 1:3, 3:1)              # rep(1,3), rep(2,2), rep(3,1)

# ===== 7. 使用dplyr进行向量化操作 =====
# library(dplyr)
# 
# 创建数据框
# df <- data.frame(
#   x = 1:100,
#   y = rnorm(100),
#   group = rep(c("A", "B"), each = 50)
# )
# 
# # mutate() - 向量化创建新列
# df <- df %>%
#   mutate(
#     x_squared = x^2,
#     y_positive = ifelse(y > 0, "正", "负"),
#     category = case_when(
#       x < 33 ~ "低",
#       x < 67 ~ "中",
#       TRUE ~ "高"
#     )
#   )
# 
# # filter() - 向量化筛选
# df_filtered <- df %>%
#   filter(x > 50, y > 0)

# ===== 8. 向量化数据转换 =====
# 创建数据
data <- data.frame(
  value = runif(100, 0, 100),
  category = sample(c("A", "B", "C"), 100, replace = TRUE)
)

# 传统方式：使用循环（慢）
# result <- numeric(nrow(data))
# for(i in 1:nrow(data)) {
#   if(data$category[i] == "A") {
#     result[i] <- data$value[i] * 1.1
#   } else if(data$category[i] == "B") {
#     result[i] <- data$value[i] * 1.2
#   } else {
#     result[i] <- data$value[i] * 1.3
#   }
# }

# 向量化方式：使用索引和映射
multiplier <- c(A = 1.1, B = 1.2, C = 1.3)
result <- data$value * multiplier[data$category]
result

# ===== 9. 向量化字符串操作 =====
names <- c("John", "Jane", "Bob", "Alice")

# 向量化字符串操作
toupper(names)                      # 全部转大写
tolower(names)                      # 全部转小写
nchar(names)                        # 每个字符串的长度
paste(names, "Smith", sep = " ")    # 向量化连接

# 向量化替换
texts <- c("apple", "banana", "grape")
gsub("a", "A", texts)              # 每个字符串中的a替换为A

# ===== 10. 向量化条件筛选 =====
x <- 1:20

# 单条件
x[x > 10]                          # 筛选大于10的元素

# 多条件
x[x > 5 & x < 15]                  # 筛选5到15之间的元素

# 使用which()（返回索引）
which(x > 10)                      # 返回满足条件的索引
x[which(x > 10)]                   # 等价于 x[x > 10]

# 使用subset()（对数据框更友好）
df <- data.frame(x = 1:20, y = runif(20))
subset(df, x > 10 & y > 0.5)

# ===== 11. 向量化的聚合操作 =====
# 创建分组数据
data <- data.frame(
  group = rep(c("A", "B", "C"), each = 10),
  value = rnorm(30)
)

# 传统方式（不推荐）
# result <- numeric(3)
# groups <- unique(data$group)
# for(i in 1:length(groups)) {
#   result[i] <- mean(data$value[data$group == groups[i]])
# }

# 向量化方式：使用tapply()
tapply(data$value, data$group, mean)

# 或使用aggregate()
aggregate(value ~ group, data, mean)

# ===== 12. 向量化矩阵运算 =====
# 创建矩阵
mat1 <- matrix(1:12, nrow = 3)
mat2 <- matrix(13:24, nrow = 3)

# 元素级运算（向量化）
mat1 + mat2                         # 对应元素相加
mat1 * mat2                         # 对应元素相乘（不是矩阵乘法）

# 矩阵乘法（使用 %*%）
mat1 %*% t(mat2)                    # 矩阵乘法

# 行和列的向量化操作
rowSums(mat1)                       # 每行求和
colSums(mat1)                       # 每列求和
rowMeans(mat1)                      # 每行均值
colMeans(mat1)                      # 每列均值

# ===== 13. 避免显式循环的技巧 =====
# 示例：计算移动平均

# 数据
x <- 1:100
window_size <- 5

# 方式1：使用循环（慢）
# moving_avg <- numeric(length(x) - window_size + 1)
# for(i in 1:(length(x) - window_size + 1)) {
#   moving_avg[i] <- mean(x[i:(i + window_size - 1)])
# }

# 方式2：使用向量化（使用filter函数或zoo包）
# library(zoo)
# moving_avg <- rollmean(x, window_size)

# 方式3：使用基础R的向量化（简化版）
# 可以使用embed()函数

# ===== 14. 向量化的优势 =====
# 1. 性能：通常快10-100倍
# 2. 简洁：代码更短、更易读
# 3. 安全性：减少索引错误
# 4. R风格：符合R的设计理念

# 性能示例
n <- 1000000
x <- runif(n)

# 循环方式
system.time({
  result1 <- numeric(n)
  for(i in 1:n) {
    result1[i] <- x[i]^2
  }
})

# 向量化方式
system.time({
  result2 <- x^2
})

# ===== 15. 实际应用：数据清洗 =====
# 创建有问题的数据
data <- data.frame(
  value = c(10, 20, -5, 30, 999, 15, NA, 25),
  category = c("A", "B", "A", "B", "A", "B", "A", "B")
)

# 向量化数据清洗
# 1. 处理异常值（999可能是缺失值代码）
data$value[data$value == 999] <- NA

# 2. 处理负值
data$value[data$value < 0] <- 0

# 3. 填充缺失值（使用组均值）
# 可以使用tapply或dplyr
group_means <- tapply(data$value, data$category, mean, na.rm = TRUE)
data$value[is.na(data$value)] <- group_means[data$category[is.na(data$value)]]

data

# ===== 16. 实际应用：特征工程 =====
# 创建数据
df <- data.frame(
  x1 = runif(100),
  x2 = runif(100),
  x3 = runif(100)
)

# 向量化创建新特征
df$sum <- df$x1 + df$x2 + df$x3                    # 求和
df$product <- df$x1 * df$x2 * df$x3                # 乘积
df$max <- pmax(df$x1, df$x2, df$x3)                # 最大值
df$min <- pmin(df$x1, df$x2, df$x3)                # 最小值
df$range <- df$max - df$min                        # 范围

head(df)

# ===== 17. 常见错误：伪向量化 =====
# 错误：在循环中使用append或c()（会复制整个向量，很慢）
# result <- c()
# for(i in 1:1000) {
#   result <- c(result, i^2)  # 每次都复制整个向量！
# }

# 正确：预分配空间
result <- numeric(1000)
for(i in 1:1000) {
  result[i] <- i^2
}

# 最好：完全向量化
result <- (1:1000)^2

# ===== 18. 向量化的限制 =====
# 有些操作确实需要循环，比如：
# - 前一个值依赖于后一个值的计算
# - 迭代算法
# - 复杂的条件逻辑

# 但即使在这些情况下，也要尽量向量化部分操作

# ===== 19. 总结：向量化思维 =====
# 1. 思考问题：能否对整个向量/矩阵操作？
# 2. 避免循环：优先使用向量化函数
# 3. 使用apply族：当需要分组操作时
# 4. 预分配空间：如果必须使用循环
# 5. 利用索引：使用逻辑索引而非循环

# ===== 20. 实践练习 =====
# 创建一个数据集，使用向量化操作完成以下任务：
data <- data.frame(
  id = 1:1000,
  score = runif(1000, 0, 100),
  category = sample(c("A", "B", "C"), 1000, replace = TRUE)
)

# 1. 计算每个类别的平均分（向量化）
tapply(data$score, data$category, mean)

# 2. 创建新列：分数等级（向量化）
data$grade <- ifelse(data$score >= 90, "优秀",
                     ifelse(data$score >= 80, "良好",
                            ifelse(data$score >= 60, "及格", "不及格")))

# 3. 筛选高分数据（向量化）
high_scores <- data[data$score > 90, ]

# 4. 标准化分数（向量化）
data$score_standardized <- (data$score - mean(data$score)) / sd(data$score)

head(data)


