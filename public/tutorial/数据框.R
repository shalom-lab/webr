# R 数据框 (Data Frame)

# 1. 创建数据框
# 使用 data.frame() 函数
df <- data.frame(
  name = c("张三", "李四", "王五"),
  age = c(25, 30, 35),
  city = c("北京", "上海", "广州"),
  stringsAsFactors = FALSE
)

print(df)

# 2. 查看数据框的基本信息
str(df)      # 查看结构
head(df)     # 查看前几行
tail(df)     # 查看后几行
nrow(df)     # 行数
ncol(df)     # 列数
dim(df)      # 维度

# 3. 访问数据框的元素
df$name          # 访问列
df[1, ]          # 访问第一行
df[, 2]          # 访问第二列
df[1, 2]         # 访问第一行第二列
df[c(1, 3), ]    # 访问第1和第3行

# 4. 添加新列
df$salary <- c(5000, 6000, 7000)
print(df)

# 5. 添加新行
new_row <- data.frame(
  name = "赵六",
  age = 28,
  city = "深圳",
  salary = 5500,
  stringsAsFactors = FALSE
)
df <- rbind(df, new_row)
print(df)

# 6. 筛选数据
# 筛选年龄大于30的记录
df[df$age > 30, ]

# 筛选特定城市的记录
df[df$city == "北京", ]

# 7. 使用内置数据集
data(mtcars)  # 加载 mtcars 数据集
head(mtcars)
summary(mtcars)

# 8. 数据框的基本操作
colnames(df)     # 列名
rownames(df)     # 行名
subset(df, age > 30)  # 子集


