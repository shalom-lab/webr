# 正则表达式系列教程
# 在R中使用正则表达式进行模式匹配

# ===== 1. 基础正则表达式语法 =====
# 字面量匹配
text <- "Hello World"
grepl("Hello", text)                 # 匹配字面量"Hello"

# 点号 (.) - 匹配任意字符
grepl("H.llo", "Hello")              # TRUE (点匹配e)
grepl("H.llo", "Hallo")              # TRUE (点匹配a)

# 字符类 [] - 匹配字符集合中的任意一个
grepl("[aeiou]", "Hello")            # 匹配任意元音字母
grepl("[0-9]", "abc123")             # 匹配任意数字
grepl("[a-z]", "ABC123")             # 匹配任意小写字母
grepl("[A-Z]", "abc123")             # 匹配任意大写字母

# ===== 2. 字符类简写 =====
# \d - 数字 (在R中需要转义: \\d)
grepl("\\d", "abc123")               # 匹配数字

# \w - 单词字符（字母、数字、下划线）
grepl("\\w", "hello")                # TRUE

# \s - 空白字符
grepl("\\s", "hello world")          # TRUE (匹配空格)

# \D, \W, \S - 否定字符类
grepl("\\D", "123abc")               # TRUE (匹配非数字)

# ===== 3. 锚点 =====
# ^ - 字符串开始
grepl("^Hello", "Hello World")       # TRUE (以Hello开头)
grepl("^World", "Hello World")       # FALSE

# $ - 字符串结束
grepl("World$", "Hello World")       # TRUE (以World结尾)
grepl("Hello$", "Hello World")       # FALSE

# \b - 单词边界
grepl("\\bHello\\b", "Hello World")  # TRUE
grepl("\\bHello\\b", "HelloWorld")   # FALSE

# ===== 4. 量词 =====
# * - 0次或多次
grepl("a*", "bbb")                   # TRUE (0次也匹配)
grepl("a*", "aaa")                   # TRUE

# + - 1次或多次
grepl("a+", "bbb")                   # FALSE (至少1次)
grepl("a+", "aaa")                   # TRUE

# ? - 0次或1次（可选）
grepl("colou?r", "color")            # TRUE (u可选)
grepl("colou?r", "colour")           # TRUE

# {n} - 恰好n次
grepl("a{3}", "aaa")                 # TRUE (恰好3个a)
grepl("a{3}", "aa")                  # FALSE

# {n,} - n次或更多
grepl("a{2,}", "aaa")                # TRUE (2次或更多)

# {n,m} - n到m次
grepl("a{2,4}", "aaa")               # TRUE (2到4次)

# ===== 5. 分组和捕获 =====
# () - 分组
text <- "abc123def456"
# 提取数字部分
regmatches(text, regexpr("\\d+", text))        # 第一个匹配
regmatches(text, gregexpr("\\d+", text))[[1]]  # 所有匹配

# 使用sub/gsub的捕获组
text <- "姓名: 张三, 年龄: 25"
sub("姓名: (\\w+), 年龄: (\\d+)", "姓名是\\1，年龄是\\2", text)

# ===== 6. 或操作符 | =====
grepl("cat|dog", "I have a cat")     # TRUE (匹配cat或dog)
grepl("cat|dog", "I have a dog")     # TRUE
grepl("cat|dog", "I have a bird")    # FALSE

# ===== 7. 贪婪 vs 非贪婪匹配 =====
# 默认是贪婪匹配
text <- "<div>content</div>"
# 贪婪匹配（默认）
regmatches(text, regexpr("<.*>", text))        # 匹配整个标签

# 非贪婪匹配（使用?）
regmatches(text, regexpr("<.*?>", text))       # 只匹配第一个标签

# ===== 8. 常用函数 =====
text_vector <- c("apple", "banana", "grape", "pineapple")

# grep() - 返回匹配的索引
grep("apple", text_vector)           # 1, 4

# grepl() - 返回逻辑向量
grepl("apple", text_vector)          # TRUE FALSE FALSE TRUE

# regexpr() - 返回第一个匹配的位置和长度
regexpr("pp", text_vector)

# gregexpr() - 返回所有匹配的位置
gregexpr("pp", text_vector)

# regmatches() - 提取匹配的文本
regmatches(text_vector, regexpr("pp", text_vector))
regmatches(text_vector, gregexpr("pp", text_vector))

# ===== 9. 实际应用：邮箱验证 =====
emails <- c("user@example.com", "invalid.email", "test@domain.co.uk")

# 简单的邮箱正则表达式（实际应用需要更复杂）
email_pattern <- "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
grepl(email_pattern, emails)

# ===== 10. 实际应用：提取电话号码 =====
text <- c("电话: 138-1234-5678", "手机: 13987654321", "座机: 010-12345678")

# 提取电话号码（简化版本）
phone_pattern <- "\\d{3,4}-?\\d{4}-?\\d{4}"
regmatches(text, regexpr(phone_pattern, text))

# ===== 11. 实际应用：提取URL =====
text <- "访问 https://www.example.com 获取更多信息"

# 提取URL（简化版本）
url_pattern <- "https?://[\\w\\.-]+"
regmatches(text, regexpr(url_pattern, text))

# ===== 12. 实际应用：数据清洗 =====
# 移除所有数字
text <- "价格是123元，数量是456"
gsub("\\d+", "", text)               # "价格是元，数量是"

# 只保留数字
gsub("\\D", "", text)                # "123456"

# 移除多余空格
text <- "这是   多个    空格"
gsub("\\s+", " ", text)              # "这是 多个 空格"

# ===== 13. 实际应用：提取日期 =====
text <- c("日期: 2023-01-15", "日期: 2023/02/20", "日期: 2023.03.25")

# 提取日期部分
date_pattern <- "\\d{4}[-/.]\\d{2}[-/.]\\d{2}"
regmatches(text, regexpr(date_pattern, text))

# ===== 14. 实际应用：验证密码强度 =====
passwords <- c("Password123!", "weak", "StrongP@ss1")

# 检查是否包含大小写字母、数字和特殊字符（简化版本）
has_upper <- grepl("[A-Z]", passwords)
has_lower <- grepl("[a-z]", passwords)
has_digit <- grepl("\\d", passwords)
has_special <- grepl("[!@#$%^&*]", passwords)
is_strong <- has_upper & has_lower & has_digit & has_special

data.frame(
  密码 = passwords,
  强度 = ifelse(is_strong, "强", "弱")
)

# ===== 15. 实际应用：文本提取 =====
# 从HTML标签中提取文本（简化示例）
html_text <- "<p>这是段落文本</p><div>这是div文本</div>"
# 移除HTML标签
gsub("<[^>]+>", "", html_text)       # "这是段落文本这是div文本"

# ===== 16. 实际应用：单词提取 =====
text <- "The quick brown fox jumps over the lazy dog"

# 提取所有单词
words <- regmatches(text, gregexpr("\\b\\w+\\b", text))[[1]]
words

# 统计单词长度
word_lengths <- nchar(words)
table(word_lengths)

# ===== 17. 高级技巧：前后查找 =====
# 正向前查找 (?=...) - 匹配后面跟着某个模式的位置
text <- "price: $100, price: $200"
# 提取$后面的数字
regmatches(text, gregexpr("(?<=\\$)\\d+", text, perl = TRUE))[[1]]

# 负向前查找 (?!...) - 匹配后面不跟着某个模式的位置
# 需要perl = TRUE

# ===== 18. 实际应用：日志分析 =====
log_lines <- c(
  "2023-01-15 10:30:00 ERROR: Database connection failed",
  "2023-01-15 10:31:00 INFO: User logged in successfully",
  "2023-01-15 10:32:00 WARNING: High CPU usage detected"
)

# 提取时间戳
timestamps <- regmatches(log_lines, regexpr("\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}", log_lines))
timestamps

# 提取日志级别
levels <- gsub(".* (ERROR|INFO|WARNING):.*", "\\1", log_lines)
levels

# 提取消息
messages <- gsub(".*: ", "", log_lines)
messages

# ===== 19. 性能优化 =====
# 对于大量文本处理，编译正则表达式可以提高性能
# 但在R中，grep/grepl等函数已经优化

# 避免过度复杂的正则表达式
# 考虑分步骤处理，而不是一个超长的正则表达式

# ===== 20. 常见错误和陷阱 =====
# 错误1：忘记转义特殊字符
grepl(".", "Hello")                  # 匹配任意字符，不是点号
grepl("\\.", "Hello.")               # 正确匹配点号

# 错误2：贪婪匹配导致的意外结果
text <- "<div><p>content</p></div>"
regmatches(text, regexpr("<.*>", text))        # 匹配整个字符串
regmatches(text, regexpr("<.*?>", text))       # 只匹配第一个标签

# 错误3：字符类中的特殊字符
grepl("[.]", "Hello.")               # 在字符类中，点号不需要转义
grepl("[\\^]", "a^b")                # 转义字符需要双重转义

# ===== 21. 调试正则表达式 =====
# 使用简单的测试案例
test_cases <- c("匹配", "不匹配", "可能匹配")
pattern <- "匹配"
result <- grepl(pattern, test_cases)
data.frame(测试案例 = test_cases, 匹配结果 = result)

# ===== 22. 综合示例：数据提取 =====
# 从混合文本中提取不同类型的信息
mixed_text <- "用户: 张三, 年龄: 25, 邮箱: zhang@example.com, 电话: 138-1234-5678"

# 提取姓名
name <- gsub(".*用户: ([^,]+).*", "\\1", mixed_text)

# 提取年龄
age <- gsub(".*年龄: (\\d+).*", "\\1", mixed_text)

# 提取邮箱
email <- regmatches(mixed_text, regexpr("\\w+@\\w+\\.\\w+", mixed_text))

# 提取电话
phone <- regmatches(mixed_text, regexpr("\\d{3}-\\d{4}-\\d{4}", mixed_text))

cat("姓名:", name, "\n")
cat("年龄:", age, "\n")
cat("邮箱:", email, "\n")
cat("电话:", phone, "\n")





