# 线性回归 (Linear Regression) 教程
# 使用 lm() 函数进行线性回归分析

# ===== 1. 简单线性回归 =====
# 创建示例数据
set.seed(123)
x <- 1:100
y <- 2 * x + 10 + rnorm(100, 0, 10)

# 拟合线性模型
model1 <- lm(y ~ x)

# 查看模型摘要
summary(model1)

# 绘制散点图和回归线
plot(x, y, 
     main = "简单线性回归",
     xlab = "X",
     ylab = "Y",
     pch = 19,
     col = "steelblue")
abline(model1, col = "red", lwd = 2)

# ===== 2. 模型诊断 =====
# 查看残差
residuals(model1)
fitted(model1)

# 残差图
plot(fitted(model1), residuals(model1),
     main = "残差图",
     xlab = "拟合值",
     ylab = "残差",
     pch = 19)
abline(h = 0, col = "red", lwd = 2)

# Q-Q图（检查正态性）
qqnorm(residuals(model1))
qqline(residuals(model1), col = "red")

# ===== 3. 多元线性回归 =====
# 创建多变量数据
set.seed(123)
x1 <- rnorm(100, 50, 15)
x2 <- rnorm(100, 30, 10)
y <- 2 * x1 + 3 * x2 + 5 + rnorm(100, 0, 5)

# 拟合多元线性模型
model2 <- lm(y ~ x1 + x2)

# 模型摘要
summary(model2)

# 查看系数
coef(model2)
confint(model2)  # 置信区间

# ===== 4. 模型预测 =====
# 使用新数据进行预测
new_data <- data.frame(x1 = c(40, 50, 60), x2 = c(25, 30, 35))

# 点预测
predictions <- predict(model2, newdata = new_data)
predictions

# 预测区间
predictions_interval <- predict(model2, 
                                newdata = new_data,
                                interval = "prediction")
predictions_interval

# 置信区间
predictions_confidence <- predict(model2,
                                  newdata = new_data,
                                  interval = "confidence")
predictions_confidence

# ===== 5. 交互项和多项式 =====
# 创建数据
x <- 1:50
y <- 2 * x + 0.1 * x^2 + rnorm(50, 0, 5)

# 线性模型（不包含二次项）
model_linear <- lm(y ~ x)

# 多项式模型（包含二次项）
model_poly <- lm(y ~ x + I(x^2))

# 比较模型
summary(model_linear)
summary(model_poly)

# 可视化
plot(x, y, pch = 19, col = "steelblue", main = "线性 vs 多项式模型")
lines(x, fitted(model_linear), col = "red", lwd = 2, lty = 2)
lines(x, fitted(model_poly), col = "blue", lwd = 2)

legend("topleft",
       legend = c("数据", "线性模型", "多项式模型"),
       col = c("steelblue", "red", "blue"),
       pch = c(19, NA, NA),
       lty = c(NA, 2, 1),
       lwd = 2)

# ===== 6. 分类变量作为预测变量 =====
# 创建数据
set.seed(123)
group <- rep(c("A", "B", "C"), each = 30)
x <- rnorm(90, 50, 10)
y <- ifelse(group == "A", 2 * x + 10,
            ifelse(group == "B", 2 * x + 20, 2 * x + 30)) + rnorm(90, 0, 5)

# 拟合模型（R会自动创建虚拟变量）
model3 <- lm(y ~ x + group)

summary(model3)

# 可视化
plot(x, y, col = as.numeric(factor(group)), pch = 19, main = "分组回归")
group_levels <- levels(factor(group))
colors <- c("red", "blue", "green")
for(i in 1:length(group_levels)) {
  subset_data <- group == group_levels[i]
  abline(lm(y[subset_data] ~ x[subset_data]), col = colors[i], lwd = 2)
}
legend("topleft", legend = group_levels, col = colors, pch = 19, lwd = 2)

# ===== 7. 模型比较 =====
# 创建嵌套模型
model_full <- lm(y ~ x1 + x2)
model_reduced <- lm(y ~ x1)

# F检验比较模型
anova(model_reduced, model_full)

# AIC和BIC
AIC(model_reduced, model_full)
BIC(model_reduced, model_full)

# ===== 8. 逐步回归 =====
# 创建更多变量的数据
set.seed(123)
x1 <- rnorm(100, 50, 15)
x2 <- rnorm(100, 30, 10)
x3 <- rnorm(100, 20, 5)
x4 <- rnorm(100, 40, 12)
y <- 2 * x1 + 3 * x2 + rnorm(100, 0, 5)  # x3和x4实际上不相关

# 全模型
model_full <- lm(y ~ x1 + x2 + x3 + x4)

# 逐步回归（向后消除）
model_step <- step(model_full, direction = "backward")

summary(model_step)

# ===== 9. 假设检验 =====
# 检验系数是否为零
summary(model2)  # t检验在summary中

# F检验（整体模型显著性）
anova(model2)

# 检验残差的正态性
shapiro.test(residuals(model2))

# 检验方差齐性（Breusch-Pagan检验，需要lmtest包）
# library(lmtest)
# bptest(model2)

# ===== 10. 使用真实数据示例 =====
# 使用内置数据集
data(mtcars)

# 探索数据
head(mtcars)
str(mtcars)

# 拟合模型：mpg ~ hp + wt
model_cars <- lm(mpg ~ hp + wt, data = mtcars)

summary(model_cars)

# 可视化
plot(mtcars$hp, mtcars$mpg, 
     pch = 19, 
     col = "steelblue",
     xlab = "马力 (hp)",
     ylab = "每加仑英里数 (mpg)",
     main = "汽车数据：马力 vs 油耗")
abline(lm(mpg ~ hp, data = mtcars), col = "red", lwd = 2)

# ===== 11. 模型诊断图的完整展示 =====
# 创建诊断图布局
par(mfrow = c(2, 2))
plot(model_cars)
par(mfrow = c(1, 1))

# ===== 12. 实用技巧 =====
# 提取模型信息
coefficients(model_cars)  # 系数
fitted(model_cars)        # 拟合值
residuals(model_cars)     # 残差
rstandard(model_cars)     # 标准化残差
rstudent(model_cars)      # 学生化残差

# R平方和调整R平方
summary(model_cars)$r.squared
summary(model_cars)$adj.r.squared

# 模型公式
formula(model_cars)





