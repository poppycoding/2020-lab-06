#!/usr/bin/env bash


# 配置path环境
D:/Dev/DB/MongoDB/MongoDB/bin

# 新建data文件夹
D:/Dev/DB/MongoDB/MongoDB/data

# 启动(界面没有任何输出,重新打开一个cmd验证mongo)
mongod -dbpath D:/Dev/DB/MongoDB/MongoDB/data

# 新开一个cmd检查是否启动成功
mongo

# 安装win服务(管理员启动cmd)
mongod --dbpath D:/Dev/DB/MongoDB/MongoDB/data --logpath D:/Dev/DB/MongoDB/MongoDB/log/mongod.log  --install

# 启动(管理员启动cmd)
net start MongoDB
net stop MongoDB
net restart MongoDB

# 查看服务(未启动服务之前,无法查看,可以通过windows的服务管理界面查看)
sc query |findstr Mongo

# 删除MongoDB服务
sc delete MongoDB


#安装可视化界面
# 官方
Compass

# 三方
Robo 3T


# 参考官方atlas可以申请免费使用mongodb cluster
https://www.mongodb.com/download-center


# 下载解压dump数据,到../Backup文件夹
curl -O -k https://raw.githubusercontent.com/tapdata/geektimemongodb-course/master/aggregation/dump.tar.gz
tar -xvf dump.tar.gz

# Backup目录下执行restore,恢复dump文件
mongorestore -h localhost:27017



# 为当前数据库创建角色,最后一个readWrite是当前数据库,三个role分别是集群,任意数据库,test数据库
db.createUser({user:"customDB",pwd:"customDB123",roles:[{role:"clusterAdmin",db:"admin" },{role:"readAnyDatabase",db:"admin" },{role:"readWrite",db:"test"},"readWrite"]})



# 创建索引
db.contact.createIndex( { "email": 1,})
# 创建唯一索引
db.contact.createIndex( { "email": 1,}, { unique: true })
# 唯一复合索引
db.contact.createIndex( { "email": 1,"name": 1 }, { unique: true } )









# TODO
# 认证方式启动,发现options: { security: { authorization: "enabled" } }中多了enabled这条信息
mongod -dbpath D:/Dev/DB/MongoDB/MongoDB/data --auth

# 默认无用户,添加用户root用户
use admin
db.createUser({"user":"root","pwd":"1234","roles":["root"]})
exit

# 退出之后重新授权:授权成功会返回1，失败返回0
use admin
db.auth('root','1234')

