# 字符串处理系列教程
# R中的字符串操作和处理

# ===== 1. 基础字符串操作 =====
# 创建字符串
str1 <- "Hello"
str2 <- "World"
str3 <- "R语言字符串处理"

# 字符串连接
paste(str1, str2)                    # 默认用空格连接
paste(str1, str2, sep = "")          # 无分隔符
paste(str1, str2, sep = "-")         # 自定义分隔符
paste0(str1, str2)                   # paste0等同于sep=""

# 多个字符串连接
paste(c("A", "B", "C"), collapse = "-")  # 向量连接
paste("A", "B", "C", sep = ", ")         # 多个参数

# ===== 2. 字符串长度 =====
nchar("Hello World")                 # 字符数
nchar(c("A", "BB", "CCC"))          # 向量中每个字符串的长度
nchar("你好世界")                    # 中文字符

# ===== 3. 大小写转换 =====
toupper("hello world")               # 转大写
tolower("HELLO WORLD")               # 转小写
casefold("Hello World", upper = TRUE)  # casefold函数

# ===== 4. 字符串截取 =====
# substr() - 按位置截取
text <- "Hello World"
substr(text, 1, 5)                   # 提取前5个字符
substr(text, 7, 11)                  # 提取第7到11个字符

# substring() - 类似substr但更灵活
substring(text, 1, 5)
substring(text, 7)                   # 从第7个字符到结尾

# 向量化操作
words <- c("Apple", "Banana", "Cherry")
substr(words, 1, 3)                  # 提取每个词的前3个字符

# ===== 5. 字符串查找和替换 =====
# grep() - 查找匹配模式
text_vector <- c("apple", "banana", "grape", "pineapple")
grep("apple", text_vector)           # 返回匹配的索引
grep("apple", text_vector, value = TRUE)  # 返回匹配的值
grep("^a", text_vector)              # 以a开头的
grep("e$", text_vector)              # 以e结尾的

# grepl() - 返回逻辑值
grepl("apple", text_vector)          # 返回TRUE/FALSE向量

# sub() - 替换第一个匹配
text <- "apple and apple"
sub("apple", "orange", text)         # 只替换第一个

# gsub() - 替换所有匹配
gsub("apple", "orange", text)        # 替换所有

# ===== 6. 字符串分割 =====
# strsplit() - 分割字符串
text <- "apple,banana,cherry"
strsplit(text, ",")                  # 按逗号分割
strsplit(text, ",")[[1]]             # 提取结果向量

# 分割多个字符串
texts <- c("a-b-c", "x-y-z", "1-2-3")
strsplit(texts, "-")                 # 返回列表

# 使用多个分隔符
text <- "apple,banana;cherry:grape"
strsplit(text, "[,;:]")              # 使用正则表达式

# ===== 7. 字符串格式化 =====
# sprintf() - 格式化字符串
sprintf("数字: %d", 123)             # 整数
sprintf("小数: %.2f", 3.14159)       # 保留2位小数
sprintf("百分比: %.1f%%", 85.5)      # 百分比
sprintf("%s 的分数是 %d", "张三", 95) # 多个参数

# format() - 格式化数字
format(1234567.89, big.mark = ",")   # 千位分隔符
format(0.1234, scientific = TRUE)    # 科学计数法

# ===== 8. 去除空白字符 =====
# trimws() - 去除首尾空白
text <- "  Hello World  "
trimws(text)                         # 去除首尾空白
trimws(text, which = "left")         # 只去除左边
trimws(text, which = "right")        # 只去除右边

# ===== 9. 字符串匹配和提取 =====
# 使用正则表达式（详见正则表达式教程）
text <- "我的邮箱是 user@example.com"
# 提取邮箱（简化示例）
# 实际使用需要更复杂的正则表达式

# ===== 10. 字符串向量操作 =====
# 创建字符串向量
names <- c("张三", "李四", "王五", "赵六")

# 添加前缀
paste("学生:", names)

# 添加后缀
paste(names, "同学", sep = "")

# 组合操作
paste("第", 1:length(names), "名:", names, sep = "")

# ===== 11. 字符串比较 =====
# 精确匹配
"apple" == "apple"                   # TRUE
"apple" == "Apple"                   # FALSE (区分大小写)

# 部分匹配
grepl("app", "apple")                # TRUE

# 排序
words <- c("zebra", "apple", "banana")
sort(words)                          # 字母顺序排序

# ===== 12. 实用示例：数据清洗 =====
# 创建包含问题的数据
messy_data <- c(
  "  John Doe  ",
  "Jane SMITH",
  "BOB JOHNSON  ",
  "  Alice Williams"
)

# 清洗数据：去除首尾空白，统一大小写
clean_data <- trimws(toupper(messy_data))
clean_data

# ===== 13. 字符串替换示例 =====
# 处理日期格式
dates <- c("2023-01-15", "2023-02-20", "2023-03-25")
# 将横线替换为斜线
gsub("-", "/", dates)

# 处理文件名
files <- c("data_file_1.csv", "data_file_2.csv", "report_file.csv")
# 移除扩展名
gsub("\\.csv$", "", files)

# ===== 14. 字符串提取示例 =====
# 从文本中提取数字
text_with_numbers <- c("价格: $100", "价格: $250", "价格: $50")
# 提取数字部分（需要正则表达式，见下节）
# gsub("[^0-9]", "", text_with_numbers)

# ===== 15. 字符串拼接技巧 =====
# 使用paste创建文件路径
base_path <- "/data"
folder <- "2023"
filename <- "report.csv"
full_path <- paste(base_path, folder, filename, sep = "/")
full_path

# 使用paste创建SQL查询（示例）
table_name <- "users"
condition <- "age > 18"
query <- paste("SELECT * FROM", table_name, "WHERE", condition)
query

# ===== 16. 处理中文字符串 =====
chinese_text <- "这是一个测试字符串"
nchar(chinese_text)                  # 字符数
substr(chinese_text, 1, 4)           # 提取前4个字符

# 中英文混合
mixed_text <- "Hello 世界"
nchar(mixed_text)                    # 正确计算字符数

# ===== 17. 字符串编码 =====
# R通常自动处理UTF-8编码
# 如果需要指定编码
# Encoding(text) <- "UTF-8"

# ===== 18. 性能提示 =====
# 对于大量字符串操作，考虑使用stringr包
# library(stringr)
# str_replace(), str_extract(), str_split() 等函数更高效

# ===== 19. 常见错误和注意事项 =====
# 错误：使用==比较多个字符串
c("a", "b") == "a"                   # 正确：向量化比较

# 注意：nchar()对NA的处理
nchar(NA)                            # 返回NA
nchar(c("a", NA, "b"))              # 正确处理NA

# ===== 20. 综合示例：文本处理 =====
# 处理日志文件格式
log_lines <- c(
  "2023-01-15 10:30:00 ERROR: Connection failed",
  "2023-01-15 10:31:00 INFO: User logged in",
  "2023-01-15 10:32:00 WARNING: High memory usage"
)

# 提取日期时间
dates_times <- substr(log_lines, 1, 19)
dates_times

# 提取日志级别
log_levels <- gsub(".* (ERROR|INFO|WARNING):.*", "\\1", log_lines)
log_levels

# 提取消息内容
messages <- gsub(".*: ", "", log_lines)
messages





