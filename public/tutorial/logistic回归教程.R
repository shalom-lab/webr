# 逻辑回归 (Logistic Regression) 教程
# 用于二分类和多分类问题

# ===== 1. 二项逻辑回归 =====
# 创建二分类数据
set.seed(123)
x <- runif(100, 0, 10)
# 使用逻辑函数生成概率
p <- 1 / (1 + exp(-(x - 5)))
# 根据概率生成二分类结果
y <- rbinom(100, 1, p)

# 拟合逻辑回归模型
model1 <- glm(y ~ x, family = binomial(link = "logit"))

# 查看模型摘要
summary(model1)

# ===== 2. 模型解释 =====
# 系数解释（对数几率比）
coef(model1)
exp(coef(model1))  # 优势比 (Odds Ratio)

# 置信区间
confint(model1)
exp(confint(model1))  # 优势比的置信区间

# ===== 3. 预测和概率 =====
# 预测概率
predicted_probs <- predict(model1, type = "response")
predicted_probs[1:10]

# 预测类别（使用0.5作为阈值）
predicted_class <- ifelse(predicted_probs > 0.5, 1, 0)
predicted_class[1:10]

# 使用新数据预测
new_data <- data.frame(x = c(2, 5, 8))
new_probs <- predict(model1, newdata = new_data, type = "response")
new_probs

# ===== 4. 可视化逻辑回归 =====
# 绘制数据点和拟合曲线
plot(x, y, 
     pch = 19,
     col = ifelse(y == 1, "red", "blue"),
     xlab = "X",
     ylab = "Y (类别)",
     main = "逻辑回归拟合")

# 绘制拟合的概率曲线
x_seq <- seq(min(x), max(x), length.out = 100)
pred_seq <- predict(model1, 
                    newdata = data.frame(x = x_seq),
                    type = "response")
lines(x_seq, pred_seq, col = "green", lwd = 2)

legend("right",
       legend = c("类别0", "类别1", "拟合曲线"),
       col = c("blue", "red", "green"),
       pch = c(19, 19, NA),
       lty = c(NA, NA, 1),
       lwd = c(NA, NA, 2))

# ===== 5. 模型评估 =====
# 混淆矩阵
table(实际 = y, 预测 = predicted_class)

# 准确率
accuracy <- mean(y == predicted_class)
accuracy

# 精确率和召回率
TP <- sum(y == 1 & predicted_class == 1)
TN <- sum(y == 0 & predicted_class == 0)
FP <- sum(y == 0 & predicted_class == 1)
FN <- sum(y == 1 & predicted_class == 0)

precision <- TP / (TP + FP)  # 精确率
recall <- TP / (TP + FN)     # 召回率
F1 <- 2 * (precision * recall) / (precision + recall)  # F1分数

cat("精确率:", precision, "\n")
cat("召回率:", recall, "\n")
cat("F1分数:", F1, "\n")

# ===== 6. ROC曲线 =====
# 计算真阳性率和假阳性率（需要手动实现或使用pROC包）
thresholds <- seq(0, 1, by = 0.01)
TPR <- numeric(length(thresholds))
FPR <- numeric(length(thresholds))

for(i in 1:length(thresholds)) {
  pred <- ifelse(predicted_probs > thresholds[i], 1, 0)
  TP_i <- sum(y == 1 & pred == 1)
  TN_i <- sum(y == 0 & pred == 0)
  FP_i <- sum(y == 0 & pred == 1)
  FN_i <- sum(y == 1 & pred == 0)
  
  TPR[i] <- TP_i / (TP_i + FN_i)  # 真阳性率
  FPR[i] <- FP_i / (FP_i + TN_i)  # 假阳性率
}

# 绘制ROC曲线
plot(FPR, TPR,
     type = "l",
     lwd = 2,
     col = "blue",
     xlab = "假阳性率 (FPR)",
     ylab = "真阳性率 (TPR)",
     main = "ROC曲线")
abline(0, 1, col = "red", lty = 2)
grid()

# AUC（曲线下面积，近似计算）
AUC <- sum(diff(FPR) * (TPR[-1] + TPR[-length(TPR)]) / 2)
cat("AUC:", AUC, "\n")

# ===== 7. 多元逻辑回归 =====
# 创建多变量数据
set.seed(123)
x1 <- runif(100, 0, 10)
x2 <- rnorm(100, 5, 2)
p <- 1 / (1 + exp(-(x1 - 5 + 0.5 * x2)))
y <- rbinom(100, 1, p)

# 拟合多元逻辑回归
model2 <- glm(y ~ x1 + x2, family = binomial)

summary(model2)

# ===== 8. 多分类逻辑回归 =====
# 创建多分类数据
set.seed(123)
x <- runif(150, 0, 10)
# 使用多项式逻辑函数
y_multi <- ifelse(x < 3, "A",
                  ifelse(x < 6, "B", "C"))
y_multi <- factor(y_multi)

# 使用nnet包进行多分类逻辑回归
# library(nnet)
# model_multi <- multinom(y_multi ~ x)
# summary(model_multi)

# ===== 9. 有序逻辑回归 =====
# 创建有序分类数据
set.seed(123)
x <- runif(100, 0, 10)
y_ordered <- cut(x, breaks = c(0, 3, 6, 10), labels = c("低", "中", "高"), ordered = TRUE)

# 使用MASS包进行有序逻辑回归
# library(MASS)
# model_ordered <- polr(y_ordered ~ x)
# summary(model_ordered)

# ===== 10. 使用真实数据 =====
# 使用内置数据集（如果有合适的）
# 创建示例：根据考试成绩预测是否通过
set.seed(123)
score <- runif(200, 0, 100)
pass <- ifelse(score > 60, 1, 0)
# 添加一些噪声
pass[score > 50 & score < 70] <- rbinom(sum(score > 50 & score < 70), 1, 0.5)

exam_data <- data.frame(score = score, pass = pass)

# 拟合模型
model_exam <- glm(pass ~ score, data = exam_data, family = binomial)

summary(model_exam)

# 可视化
plot(exam_data$score, exam_data$pass,
     pch = 19,
     col = ifelse(exam_data$pass == 1, "green", "red"),
     xlab = "考试成绩",
     ylab = "是否通过 (0=否, 1=是)",
     main = "考试成绩与通过率的关系")

score_seq <- seq(0, 100, by = 1)
pred_seq <- predict(model_exam,
                    newdata = data.frame(score = score_seq),
                    type = "response")
lines(score_seq, pred_seq, col = "blue", lwd = 2)

abline(v = 60, col = "gray", lty = 2)
legend("right",
       legend = c("未通过", "通过", "拟合曲线", "及格线"),
       col = c("red", "green", "blue", "gray"),
       pch = c(19, 19, NA, NA),
       lty = c(NA, NA, 1, 2),
       lwd = c(NA, NA, 2, 1))

# ===== 11. 模型诊断 =====
# 残差分析（逻辑回归的残差分析较复杂）
# 使用Pearson残差
pearson_residuals <- residuals(model_exam, type = "pearson")
plot(fitted(model_exam), pearson_residuals,
     xlab = "拟合概率",
     ylab = "Pearson残差",
     main = "残差图")
abline(h = 0, col = "red", lwd = 2)

# ===== 12. 模型比较 =====
# 比较不同模型
model_null <- glm(pass ~ 1, data = exam_data, family = binomial)
model_full <- glm(pass ~ score, data = exam_data, family = binomial)

# 似然比检验
anova(model_null, model_full, test = "Chisq")

# AIC比较
AIC(model_null, model_full)

# ===== 13. 交互项 =====
# 创建包含交互项的数据
set.seed(123)
x1 <- runif(100, 0, 10)
x2 <- runif(100, 0, 5)
p <- 1 / (1 + exp(-(x1 - 5 + 0.5 * x2 - 0.1 * x1 * x2)))
y <- rbinom(100, 1, p)

model_interaction <- glm(y ~ x1 * x2, family = binomial)
summary(model_interaction)


