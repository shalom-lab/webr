# 基础R包作图系列
# 使用R基础包进行数据可视化

# ===== 1. 基础绘图函数 =====
# 创建示例数据
x <- 1:100
y <- sin(x / 10) * 10 + rnorm(100, 0, 2)

# plot() - 散点图
plot(x, y, 
     main = "基础散点图",
     xlab = "X轴", 
     ylab = "Y轴",
     col = "steelblue",
     pch = 19)

# ===== 2. 折线图 =====
plot(x, y, 
     type = "l",
     main = "折线图",
     xlab = "X轴",
     ylab = "Y轴",
     col = "darkred",
     lwd = 2)

# ===== 3. 柱状图 =====
data <- c(23, 45, 56, 78, 32, 67)
names(data) <- c("A", "B", "C", "D", "E", "F")

barplot(data,
        main = "柱状图示例",
        xlab = "类别",
        ylab = "数值",
        col = rainbow(6),
        border = "black")

# ===== 4. 直方图 =====
# 生成正态分布数据
normal_data <- rnorm(1000, mean = 50, sd = 15)

hist(normal_data,
     main = "直方图 - 正态分布",
     xlab = "数值",
     ylab = "频数",
     col = "lightblue",
     border = "black",
     breaks = 30)

# ===== 5. 箱线图 =====
# 创建多组数据
group1 <- rnorm(100, mean = 50, sd = 10)
group2 <- rnorm(100, mean = 60, sd = 12)
group3 <- rnorm(100, mean = 55, sd = 15)

boxplot(group1, group2, group3,
        names = c("组1", "组2", "组3"),
        main = "箱线图对比",
        col = c("lightcoral", "lightblue", "lightgreen"),
        border = "black")

# ===== 6. 饼图 =====
pie_data <- c(30, 25, 20, 15, 10)
names(pie_data) <- c("类别A", "类别B", "类别C", "类别D", "类别E")

pie(pie_data,
    main = "饼图示例",
    col = rainbow(5),
    labels = paste(names(pie_data), "\n", pie_data, "%"))

# ===== 7. 多图布局 =====
# 创建2x2的图形布局
par(mfrow = c(2, 2))

plot(x, y, type = "l", main = "折线图")
barplot(data, main = "柱状图")
hist(normal_data, main = "直方图", breaks = 20)
boxplot(group1, group2, group3, names = c("1", "2", "3"), main = "箱线图")

# 恢复默认布局
par(mfrow = c(1, 1))

# ===== 8. 图形参数设置 =====
# 设置图形参数
par(bg = "white",
    col.main = "darkblue",
    col.lab = "darkgreen",
    font.main = 2,  # 粗体标题
    cex.main = 1.2,  # 标题大小
    cex.lab = 1.0)   # 坐标轴标签大小

plot(x, y,
     main = "自定义样式示例",
     xlab = "X轴标签",
     ylab = "Y轴标签",
     col = "steelblue",
     pch = 19,
     cex = 0.8)

# ===== 9. 添加图例 =====
plot(x, y, type = "l", col = "blue", lwd = 2, main = "带图例的图形")
lines(x, y + 5, col = "red", lwd = 2)
lines(x, y - 5, col = "green", lwd = 2)

legend("topright",
       legend = c("系列1", "系列2", "系列3"),
       col = c("blue", "red", "green"),
       lwd = 2,
       lty = 1)

# ===== 10. 保存图形 =====
# 保存为PNG格式
# png("plot_example.png", width = 800, height = 600)
# plot(x, y, main = "保存的图形")
# dev.off()

# 保存为PDF格式
# pdf("plot_example.pdf", width = 8, height = 6)
# plot(x, y, main = "保存的图形")
# dev.off()





