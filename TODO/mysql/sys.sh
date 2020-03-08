#!/usr/bin/env bash

#mysql手写ping程序获取连接时,报错时区问题,可以临时设置数据库时区命令(或者代码里设置url拼接加上时区&serverTimezone=GMT%2B8)
#查看
show variables like "%time_zone%";
#修改
set global time_zone = '+8:00';
#刷新
flush privileges;



#查看数据库版本
mysql -v




#查看表结构信息(客户端命令mysql -uroot -p 之后才能验证\G,gui界面语法错误)
SHOW CREATE TABLE table_name\G



#Support列表示该存储引擎是否可用，DEFAULT值代表是当前服务器程序的默认存储引擎。
#Comment列是对存储引擎的一个描述，英文的，将就着看吧。Transactions列代表该存储引擎是否支持事务处理。
#XA列代表着该存储引擎是否支持分布式事务。SavePoints代表着该存储引擎是否支持部分事务回滚
SHOW ENGINES;

