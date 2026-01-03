# R 函数

# 1. 定义函数
# 基本语法：函数名 <- function(参数1, 参数2, ...) { 函数体 }

# 示例：计算两个数的和
add <- function(a, b) {
  return(a + b)
}

# 调用函数
result <- add(3, 5)
print(result)

# 2. 带默认参数的函数
greet <- function(name, greeting = "Hello") {
  paste(greeting, name)
}

greet("张三")
greet("李四", "你好")

# 3. 多参数函数
calculate <- function(x, y, operation = "add") {
  if (operation == "add") {
    return(x + y)
  } else if (operation == "multiply") {
    return(x * y)
  } else {
    return("Unknown operation")
  }
}

calculate(5, 3, "add")
calculate(5, 3, "multiply")

# 4. 匿名函数
square <- function(x) x^2
square(5)

# 或者使用匿名函数
sapply(1:5, function(x) x^2)

# 5. 递归函数（计算阶乘）
factorial_func <- function(n) {
  if (n <= 1) {
    return(1)
  } else {
    return(n * factorial_func(n - 1))
  }
}

factorial_func(5)


