# ================================ System(V4.0) ================================
# 查看版本
mongo --nodb

################################## USER #####################################
# Read:允许用户读取指定数据库
# readWrite:允许用户读写指定数据库
# dbAdmin:允许用户在指定数据库中执行管理函数.如索引创建.删除.查看统计或访问system.profile
# userAdmin:允许用户向system.users集合写入.可以找指定数据库里创建.删除和管理用户
# clusterAdmin:只在admin数据库中可用.赋予用户所有分片和复制集相关函数的管理权限
# readAnyDatabase:只在admin数据库中可用.赋予用户所有数据库的读权限
# readWriteAnyDatabase:只在admin数据库中可用.赋予用户所有数据库的读写权限
# userAdminAnyDatabase:只在admin数据库中可用.赋予用户所有数据库的userAdmin权限,不能进行关闭数据库等操作
# dbAdminAnyDatabase:只在admin数据库中可用.赋予用户所有数据库的dbAdmin权限
# root:只在admin数据库中可用,超级权限,用于关闭数据库 db.shutdownServer()

# 首次启动monggo没有账号密码
mongo

# 1.创建admin角色
db.createUser({user: "admin", pwd: "admin123", roles: [{ role: "userAdminAnyDatabase", db: "admin" }]})
# 2.创建root角色
db.createUser({user: "root",pwd: "root123",roles: [{role: "root", db: "admin" }]})

# 为person数据库创建角色,最后一个readWrite是当前数据库,三个role分别是集群,任意数据库,test数据库(需要admin角色)
# 一定要切换到所在数据库上去创建用户,不然创建的用户还是属于admin
# 当person不存在时自动创建,show dbs不会显示,直到插入数据才会显示
use person
db.createUser({user:"username",pwd:"1234",roles:[{role:"clusterAdmin",db:"admin" },{role:"readAnyDatabase",db:"admin" },{role:"readWrite",db:"test"},"readWrite"]})
db.createUser({user:"username",pwd:"1234",roles:[{role:"readWrite",db:"test"},"readWrite"]})

# 查看所有用户(admin角色)
db.system.users.find()
show users

# 查看test库的用户
use test
show users

# 删除username用户(admin)
db.system.users.remove({user:"username"})
# 删除所有
db.system.users.remove({})

# 连接数据库test
mongo mongodb://username:password@localhost:27017/test


################################## INDEX #####################################
# 创建索引
db.contact.createIndex({ "email": 1})
# 创建唯一索引
db.contact.createIndex({ "email": 1}, { unique: true })
# 唯一复合索引
db.contact.createIndex({ "email": 1, "name": 1 }, { unique: true })



################################## TOOL #####################################
mongodump -h 127.0.0.1:27017 -d test -c test --oplog
mongorestore -h 127.0.0.1:27017 -d test -c test xxx.bson
