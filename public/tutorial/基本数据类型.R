# R 基本数据类型

# 1. 数值型 (numeric)
x <- 3.14
y <- 10
class(x)  # 查看数据类型

# 2. 整数型 (integer)
z <- 5L  # 使用 L 后缀表示整数
class(z)

# 3. 字符型 (character)
name <- "R语言"
greeting <- 'Hello World'
class(name)

# 4. 逻辑型 (logical)
is_true <- TRUE
is_false <- FALSE
class(is_true)

# 5. 复数型 (complex)
comp <- 3 + 4i
class(comp)

# 6. 向量 (vector) - 同一类型元素的集合
nums <- c(1, 2, 3, 4, 5)
chars <- c("a", "b", "c")
logicals <- c(TRUE, FALSE, TRUE)

# 7. 类型转换
num_str <- as.character(123)
char_num <- as.numeric("456")





