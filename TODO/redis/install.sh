#!/usr/bin/env bash
# https://blog.csdn.net/u012060033/article/details/78553124
# https://ywnz.com/linuxyffq/3415.html

    #####################################
    #
    #        单节点redis集群搭建
    #
    #####################################

# 下载tar: http://download.redis.io/releases/
wget http://download.redis.io/releases/redis-5.0.2.tar.gz

# 解压编译
tar zxvf redis-5.0.2.tar.gz
cd redis-5.0.2

# 用到gcc编译出redis-server等命令
make
# make报错: make[3]: gcc: Command not found >> 安装gcc之后make
yum -y install gcc automake autoconf libtool make


# 文件夹创建
mkdir redis-cluster-confs
mkdir redis-cluster-logs
mkdir redis-cluster-nodes
mkdir redis-cluster-pids

cd redis-cluster-confs
mkdir 4379
mkdir 5379
mkdir 6379
mkdir 7379
mkdir 8379
mkdir 9379

cp ../redis.conf 4379


# 修改对应的配置文件(port/pidfile需要随着文件夹修改)
bind 192.168.200.156 #69行
protected-mode no #88行 非保护模式
port 4379 #92行
daemonize yes #136行 后台运行
pidfile /data-manager/app/redis-5.0.2/redis-cluster-pids/redis-4379.pid #158行
logfile /data-manager/app/redis-5.0.2/redis-cluster-logs/log-4379.log #171行
appendonly yes #699行
cluster-enabled yes #838行 启用集群模式
cluster-config-file /data-manager/app/redis-5.0.2/redis-cluster-nodes/node-4379.conf #846行
cluster-node-timeout 15000 #852行 #超时时间
# 待定配置
#cluster-replica-validity-factor 10 #897行
#cluster-migration-barrier 1 #916行
#cluster-require-full-coverage yes #929行

# 以4379为模板,修改对应的ip,host,pid,log,conf等
cp 4379/redis.conf 5379/
cp 4379/redis.conf 6379/
cp 4379/redis.conf 7379/
cp 4379/redis.conf 8379/
cp 4379/redis.conf 9379/





# 启动节点
src/redis-server ./redis-cluster-confs/4379/redis.conf
src/redis-server ./redis-cluster-confs/5379/redis.conf
src/redis-server ./redis-cluster-confs/6379/redis.conf
src/redis-server ./redis-cluster-confs/7379/redis.conf
src/redis-server ./redis-cluster-confs/8379/redis.conf
src/redis-server ./redis-cluster-confs/9379/redis.conf

# 启动集群(注意至少6个节点)
#ERROR: Invalid configuration for cluster creation.Redis Cluster requires at least 3 master nodes. At least 6 nodes are required.
src/redis-cli --cluster create 192.168.200.156:4379 192.168.200.156:5379 192.168.200.156:6379 192.168.200.156:7379 192.168.200.156:8379 192.168.200.156:9379 --cluster-replicas 1

#>>> Performing hash slots allocation on 6 nodes...
#[WARNING] Some slaves are in the same host as their master
#Can I set the above configuration? (type 'yes' to accept): yes
#.....
#[OK] All 16384 slots covered. 启动成功 !




# 连接进入命令行界面 -host -port (-a password)
./src/redis-cli -h 192.168.200.156 -p 6379
# 查看所有key
keys *
# slave节点不可以直接set: (error) MOVED 3300 192.168.200.156:4379需要到master节点操作,可以看启动集群信息主从分配,也可以安装manager查看



# 关闭集群,杀死所有进程,删除log,pid,node文件
ps -ef | grep redis | grep -v grep | awk '{print $2}' | xargs kill -9
rm -rf redis-cluster-pids/redis-*
rm -rf redis-cluster-node/node-*
rm -rf redis-cluster-log/log_*


# 安装web管理页面 https://github.com/ngbdf/redis-manager/wiki
# 下载tar包,解压修改application.yml中mysql账号密码(注意乱码问题,最好通过vim修改),启动之后访问8182端口配置即可
192.168.200.156:4379,192.168.200.156:5379,192.168.200.156:6379,192.168.200.156:7379,192.168.200.156:8379,192.168.200.156:9379

# 注意,若monitor界面的查询命令失效,且数据库显示dbNaN,是由于redis数据库中无数据导致,手动set,get几次,再尝试查询dbNaN变成db(0)即可 !
