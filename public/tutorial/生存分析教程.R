# 生存分析 (Survival Analysis) 教程
# 分析事件发生时间和生存概率

# ===== 1. 安装和加载包 =====
# install.packages(c("survival", "survminer"))
library(survival)
# library(survminer)  # 用于更美观的图形

# ===== 2. 创建生存数据 =====
# 生存数据通常包含：
# - 时间（time）：观察时间或事件发生时间
# - 状态（status）：0=删失（censored），1=事件发生（event）
# - 协变量：可能影响生存的其他变量

set.seed(123)
n <- 100

# 创建模拟生存数据
time <- rexp(n, rate = 0.1)  # 指数分布生成生存时间
status <- rbinom(n, 1, 0.7)  # 70%的事件率
group <- sample(c("A", "B"), n, replace = TRUE)
age <- rnorm(n, 50, 10)

# 创建生存对象
surv_data <- data.frame(
  time = time,
  status = status,
  group = group,
  age = age
)

head(surv_data)

# ===== 3. 创建生存对象 (Surv对象) =====
# 使用 Surv() 函数创建生存对象
surv_obj <- Surv(time = surv_data$time, event = surv_data$status)
surv_obj[1:10]  # 查看前10个观察

# 解释：
# - 数字表示时间
# - + 表示删失（censored）
# - 无+表示事件发生

# ===== 4. Kaplan-Meier 估计 =====
# 估计整体生存函数
km_fit <- survfit(Surv(time, status) ~ 1, data = surv_data)
summary(km_fit)

# 绘制生存曲线
plot(km_fit,
     main = "Kaplan-Meier生存曲线",
     xlab = "时间",
     ylab = "生存概率",
     col = "blue",
     lwd = 2)

# 添加置信区间
plot(km_fit,
     conf.int = TRUE,
     main = "Kaplan-Meier生存曲线（带置信区间）",
     xlab = "时间",
     ylab = "生存概率",
     col = "blue",
     lwd = 2)

# ===== 5. 分组比较 =====
# 按组比较生存曲线
km_group <- survfit(Surv(time, status) ~ group, data = surv_data)

# 绘制分组生存曲线
plot(km_group,
     col = c("red", "blue"),
     lwd = 2,
     main = "分组生存曲线比较",
     xlab = "时间",
     ylab = "生存概率")
legend("topright",
       legend = c("组A", "组B"),
       col = c("red", "blue"),
       lwd = 2)

# 查看分组统计
summary(km_group)

# ===== 6. Log-rank 检验 =====
# 检验两组生存曲线是否有显著差异
survdiff(Surv(time, status) ~ group, data = surv_data)

# 结果解释：
# - p值 < 0.05 表示两组生存曲线有显著差异
# - 卡方值越大，差异越显著

# ===== 7. Cox比例风险模型 =====
# 单变量Cox模型
cox_model1 <- coxph(Surv(time, status) ~ group, data = surv_data)
summary(cox_model1)

# 解释：
# - exp(coef) 是风险比（Hazard Ratio, HR）
# - HR > 1 表示风险增加，HR < 1 表示风险降低
# - p值检验系数是否显著

# 多变量Cox模型
cox_model2 <- coxph(Surv(time, status) ~ group + age, data = surv_data)
summary(cox_model2)

# ===== 8. 模型诊断 =====
# 检验比例风险假设（Schoenfeld残差）
# 需要先拟合模型
test_ph <- cox.zph(cox_model2)
test_ph

# 绘制Schoenfeld残差图
par(mfrow = c(1, 2))
plot(test_ph[1])  # group的残差图
plot(test_ph[2])  # age的残差图
par(mfrow = c(1, 1))

# 如果p值 < 0.05，可能违反比例风险假设

# ===== 9. 预测和风险评分 =====
# 计算每个观察的风险评分
risk_scores <- predict(cox_model2, type = "risk")
head(risk_scores)

# 添加风险评分到数据
surv_data$risk_score <- risk_scores

# 按风险评分分组
surv_data$risk_group <- ifelse(risk_scores > median(risk_scores), "高风险", "低风险")

# 绘制风险分组的生存曲线
km_risk <- survfit(Surv(time, status) ~ risk_group, data = surv_data)
plot(km_risk,
     col = c("green", "red"),
     lwd = 2,
     main = "风险分组生存曲线",
     xlab = "时间",
     ylab = "生存概率")
legend("topright",
       legend = c("低风险", "高风险"),
       col = c("green", "red"),
       lwd = 2)

# ===== 10. 中位生存时间 =====
# 计算中位生存时间
quantile(km_fit, probs = 0.5)

# 计算特定时间点的生存概率
summary(km_fit, times = c(10, 20, 30))

# ===== 11. 使用真实数据示例 =====
# 使用survival包内置数据
data(lung)
head(lung)
?lung  # 查看数据说明

# 创建生存对象
lung$surv_obj <- Surv(lung$time, lung$status)

# Kaplan-Meier估计
km_lung <- survfit(Surv(time, status) ~ sex, data = lung)
plot(km_lung,
     col = c("pink", "blue"),
     lwd = 2,
     main = "肺癌数据：性别对生存的影响",
     xlab = "时间（天）",
     ylab = "生存概率")
legend("topright",
       legend = c("女性", "男性"),
       col = c("pink", "blue"),
       lwd = 2)

# Log-rank检验
survdiff(Surv(time, status) ~ sex, data = lung)

# Cox模型
cox_lung <- coxph(Surv(time, status) ~ age + sex + ph.ecog, data = lung)
summary(cox_lung)

# ===== 12. 竞争风险分析 =====
# 当存在多种事件类型时，使用竞争风险模型
# 需要cmprsk包
# install.packages("cmprsk")
# library(cmprsk)

# 创建竞争风险数据（示例）
# set.seed(123)
# time_cr <- rexp(100, 0.1)
# event_type <- sample(0:2, 100, replace = TRUE, prob = c(0.3, 0.4, 0.3))
# # 0=删失，1=事件类型1，2=事件类型2

# ===== 13. 参数生存模型 =====
# 除了Cox模型，还可以使用参数模型
# 假设特定的分布（如指数、Weibull等）

# Weibull分布模型
# 需要先拟合
# weibull_fit <- survreg(Surv(time, status) ~ group + age, data = surv_data, dist = "weibull")
# summary(weibull_fit)

# ===== 14. 时间依赖协变量 =====
# 当协变量随时间变化时，使用时间依赖Cox模型
# 需要创建时间依赖数据集

# 创建时间依赖数据（简化示例）
# 实际应用中需要更复杂的数据结构
# cox_td <- coxph(Surv(time1, time2, status) ~ covariate, data = time_dependent_data)

# ===== 15. 分层Cox模型 =====
# 当某个变量不满足比例风险假设时，可以将其作为分层变量
cox_stratified <- coxph(Surv(time, status) ~ age + strata(group), data = surv_data)
summary(cox_stratified)

# ===== 16. 交互项 =====
# 检验变量间的交互作用
cox_interaction <- coxph(Surv(time, status) ~ group * age, data = surv_data)
summary(cox_interaction)

# ===== 17. 模型选择 =====
# 比较不同模型
AIC(cox_model1)  # 单变量模型
AIC(cox_model2)  # 多变量模型

# 逐步回归（需要MASS包）
# library(MASS)
# cox_step <- stepAIC(cox_model2, direction = "both")

# ===== 18. 预测新个体的生存概率 =====
# 创建新数据
new_data <- data.frame(
  group = c("A", "B"),
  age = c(45, 55)
)

# 预测风险比
predict(cox_model2, newdata = new_data, type = "risk")

# 预测生存曲线（需要基线的生存函数）
# base_surv <- survfit(cox_model2)
# pred_surv <- survfit(cox_model2, newdata = new_data)
# plot(pred_surv, col = 1:2, lwd = 2)

# ===== 19. 高级可视化（使用survminer包） =====
# 如果安装了survminer包，可以使用更美观的图形
# library(survminer)
# 
# # 绘制更美观的生存曲线
# ggsurvplot(km_group,
#            pval = TRUE,           # 显示p值
#            conf.int = TRUE,       # 显示置信区间
#            risk.table = TRUE,     # 显示风险表
#            legend.labs = c("组A", "组B"),
#            palette = c("red", "blue"),
#            title = "分组生存曲线比较")

# ===== 20. 实际应用示例：临床试验数据分析 =====
# 模拟临床试验数据
set.seed(123)
n_treatment <- 50
n_control <- 50

# 治疗组数据
treatment_time <- rexp(n_treatment, rate = 0.08)
treatment_status <- rbinom(n_treatment, 1, 0.8)

# 对照组数据
control_time <- rexp(n_control, rate = 0.12)
control_status <- rbinom(n_control, 1, 0.75)

# 合并数据
clinical_data <- data.frame(
  time = c(treatment_time, control_time),
  status = c(treatment_status, control_status),
  treatment = rep(c("治疗组", "对照组"), c(n_treatment, n_control))
)

# Kaplan-Meier估计
km_clinical <- survfit(Surv(time, status) ~ treatment, data = clinical_data)

# 绘制生存曲线
plot(km_clinical,
     col = c("green", "red"),
     lwd = 2,
     main = "临床试验生存曲线",
     xlab = "时间（月）",
     ylab = "生存概率")
legend("topright",
       legend = c("治疗组", "对照组"),
       col = c("green", "red"),
       lwd = 2)

# Log-rank检验
survdiff(Surv(time, status) ~ treatment, data = clinical_data)

# Cox模型
cox_clinical <- coxph(Surv(time, status) ~ treatment, data = clinical_data)
summary(cox_clinical)

# 解释结果
# - 如果治疗组的HR < 1，说明治疗有效
# - 可以计算需要治疗的人数（NNT）等指标

# ===== 21. 注意事项和常见问题 =====
# 1. 删失数据的处理：确保正确编码（0=删失，1=事件）
# 2. 比例风险假设：在使用Cox模型前检验
# 3. 样本量：确保有足够的事件数
# 4. 时间尺度：明确时间的单位（天、月、年等）
# 5. 时间零点：明确定义时间的起点

# ===== 22. 综合示例：多变量分析 =====
# 使用lung数据进行完整的多变量分析
data(lung)

# 数据预处理
lung_clean <- lung[complete.cases(lung[, c("time", "status", "age", "sex", "ph.ecog")]), ]

# 多变量Cox模型
cox_full <- coxph(Surv(time, status) ~ age + sex + ph.ecog + wt.loss, data = lung_clean)
summary(cox_full)

# 模型诊断
test_ph_full <- cox.zph(cox_full)
test_ph_full

# 绘制诊断图
par(mfrow = c(2, 2))
plot(test_ph_full)
par(mfrow = c(1, 1))

# 如果有变量违反比例风险假设，可以考虑：
# 1. 将其作为分层变量
# 2. 添加时间交互项
# 3. 使用参数模型


