#!/usr/bin/env bash

#windows: neo4j cmd
neo4j.bat status | stop | start | restart

#linuxs: neo4j cmd
bin/neo4j status | stop | start | restart

curl http://localhost:7474





#changePwd 没有忘记密码,修改密码
:server change-password

#deletePwd 忘记密码
删除data/dbms/auth文件--重新启动




#数据备份迁移,window下用neo4j-admin.bat,社区版需要停止服务后备份!
#备份前停止服务,不能kill进程,必须stop
bin/neo4j stop

#linux备份
bin/neo4j-admin dump --database=graph.db --to=/home/2018-11-29.dump

#linux迁移
bin/neo4j-admin load --from=/home/2016-10-11.dump --database=graph.db --force
