# ================================ System(V3.2) ================================

# 查看redis版本
redis-server -v
redis-cli -v


# 进入cli
redis-cli
redis-cli -h 127.0.0.1 -p 6379


# 设置密码,修改conf的属性: requirepass 1234
# 查看当前密码
config get requirepass
# 修改conf需要重启生效,或者set命令生效
config set requirepass 1234
# 认证登陆
auth 1234


# 检索bigkey,-i参数可选(每100条睡眠0.1s)
redis-cli -h localhost -p 6379 --bigkeys -i 0.1

