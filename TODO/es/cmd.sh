#!/usr/bin/env bash


# 查看es版本
curl -XGET 'localhost:9200'

# 查看索引状态
curl -XGET 'localhost:9200/_cat/indices?v&pretty'


########### 新建es用户操作
useradd es
passwd es


# start es (注意开放端口或防火墙关闭)-d（daemonize） Starts Elasticsearch in the background
./elasticsearch -d
# 或者
nohup bin/elasticsearch &

curl http://localhost:9200





# install es head
Git clone git://github.com/mobz/elasticsearch-head.git
Cd elasticsearch-head
Npm install

# start head (安装前要完成nodejs, grunt的安装,npm方式启动，在head插件目录中执行 )
grunt server &
Open http://localhost:9100



######### 切换root用户修改，并退出shell控制台，重新连接

# 安装错误 [1]: max file descriptors [4096] for elasticsearch process likely too low, increase to at least [65536]
vim /etc/security/limits.conf
# 添加如下
* soft nofile 65536
* hard nofile 131072
* soft nproc 4096
* hard nproc 4096

# 安装错误 [3]: max virtual memory areas vm.max_map_count [65530] likely too low, increase to at least [262144]
vim /etc/sysctl.conf
# 添加
vm.max_map_count=655360
# 执行
sysctl -p
