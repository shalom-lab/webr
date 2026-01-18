# ggplot2 和 tidyverse 教程
# 使用现代R数据可视化语法

# ===== 1. 安装和加载包 =====
# install.packages(c("ggplot2", "dplyr", "tidyr", "readr"))
library(ggplot2)
library(dplyr)
library(tidyr)

# ===== 2. ggplot2 基础语法 =====
# 创建示例数据
df <- data.frame(
  x = 1:100,
  y = sin(1:100 / 10) * 10 + rnorm(100, 0, 2),
  group = rep(c("A", "B"), each = 50)
)

# 基础散点图
ggplot(df, aes(x = x, y = y)) +
  geom_point()

# 添加颜色分组
ggplot(df, aes(x = x, y = y, color = group)) +
  geom_point() +
  labs(title = "分组散点图",
       x = "X轴",
       y = "Y轴",
       color = "分组")

# ===== 3. 常用几何对象 =====
# 散点图
p1 <- ggplot(df, aes(x = x, y = y)) +
  geom_point(color = "steelblue", alpha = 0.6)

# 折线图
p2 <- ggplot(df, aes(x = x, y = y)) +
  geom_line(color = "darkred", linewidth = 1)

# 柱状图
p3 <- ggplot(df %>% count(group), aes(x = group, y = n)) +
  geom_col(fill = "lightblue", color = "black")

# 直方图
p4 <- ggplot(df, aes(x = y)) +
  geom_histogram(bins = 30, fill = "lightgreen", color = "black")

# ===== 4. 使用 dplyr 进行数据操作 =====
# 创建更复杂的数据
df_complex <- data.frame(
  category = rep(c("A", "B", "C"), each = 50),
  value = c(rnorm(50, 10, 2), rnorm(50, 15, 3), rnorm(50, 12, 2.5)),
  group = rep(rep(c("X", "Y"), each = 25), 3)
)

# 数据汇总
df_summary <- df_complex %>%
  group_by(category, group) %>%
  summarise(
    mean_value = mean(value),
    sd_value = sd(value),
    n = n(),
    .groups = "drop"
  )

# 可视化汇总结果
ggplot(df_summary, aes(x = category, y = mean_value, fill = group)) +
  geom_col(position = "dodge", color = "black") +
  geom_errorbar(aes(ymin = mean_value - sd_value, 
                    ymax = mean_value + sd_value),
                position = position_dodge(0.9),
                width = 0.2) +
  labs(title = "分组柱状图（带误差棒）",
       x = "类别",
       y = "均值",
       fill = "分组")

# ===== 5. 分面 (Faceting) =====
ggplot(df_complex, aes(x = value)) +
  geom_histogram(bins = 20, fill = "steelblue", color = "black") +
  facet_wrap(~ category, ncol = 3) +
  labs(title = "分面直方图")

# 使用两个变量分面
ggplot(df_complex, aes(x = value)) +
  geom_histogram(bins = 20, fill = "lightgreen", color = "black") +
  facet_grid(group ~ category) +
  labs(title = "网格分面图")

# ===== 6. 主题设置 =====
# 使用内置主题
p <- ggplot(df, aes(x = x, y = y, color = group)) +
  geom_point() +
  labs(title = "不同主题示例")

# 经典主题
p + theme_classic()

# 暗色主题
p + theme_dark()

# 最小主题
p + theme_minimal()

# ===== 7. 颜色和填充 =====
# 使用调色板
ggplot(df_complex, aes(x = category, y = value, fill = group)) +
  geom_boxplot() +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "使用调色板的箱线图")

# 手动设置颜色
ggplot(df_complex, aes(x = category, y = value, fill = group)) +
  geom_boxplot() +
  scale_fill_manual(values = c("X" = "#FF6B6B", "Y" = "#4ECDC4")) +
  labs(title = "自定义颜色")

# ===== 8. 统计变换 =====
# 添加回归线
ggplot(df, aes(x = x, y = y)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(title = "散点图与线性回归线")

# 添加平滑曲线
ggplot(df, aes(x = x, y = y)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "loess", color = "blue", se = TRUE) +
  labs(title = "散点图与平滑曲线")

# ===== 9. 坐标轴变换 =====
# 对数坐标
df_exp <- data.frame(x = 1:50, y = exp(1:50 / 10))

ggplot(df_exp, aes(x = x, y = y)) +
  geom_line() +
  scale_y_log10() +
  labs(title = "对数坐标示例")

# 坐标轴范围限制
ggplot(df, aes(x = x, y = y)) +
  geom_point() +
  xlim(0, 50) +
  ylim(-20, 20) +
  labs(title = "限制坐标轴范围")

# ===== 10. 组合多个图层 =====
ggplot(df_complex, aes(x = category, y = value)) +
  geom_violin(aes(fill = category), alpha = 0.5) +
  geom_boxplot(width = 0.2, fill = "white", outlier.shape = NA) +
  geom_jitter(width = 0.1, alpha = 0.3) +
  scale_fill_brewer(palette = "Pastel1") +
  labs(title = "组合图形：小提琴图 + 箱线图 + 散点",
       x = "类别",
       y = "数值") +
  theme_minimal()

# ===== 11. 使用管道操作符 =====
# 数据处理和可视化的完整流程
df_complex %>%
  filter(category == "A") %>%
  group_by(group) %>%
  summarise(mean_val = mean(value), .groups = "drop") %>%
  ggplot(aes(x = group, y = mean_val, fill = group)) +
  geom_col() +
  labs(title = "使用管道操作的数据分析流程",
       x = "分组",
       y = "均值")

# ===== 12. 保存图形 =====
# 创建图形对象
final_plot <- ggplot(df, aes(x = x, y = y, color = group)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "最终图形示例") +
  theme_minimal()

# 保存图形（在WebR中需要特殊处理）
# ggsave("plot.png", final_plot, width = 10, height = 6, dpi = 300)

# 显示图形
final_plot





