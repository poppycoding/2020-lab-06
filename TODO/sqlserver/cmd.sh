#!/usr/bin/env bash


# sqlserver安装下载express免费版本,注意系统语言(否则安装出现licence问题)


# 配置sa用户账号密码,注意配置tcp/ip才可以连接ip
# sa用户启用 https://blog.csdn.net/jiben2qingshan/article/details/8065808
# ip配置1433 https://social.msdn.microsoft.com/Forums/sqlserver/en-US/3c832592-c0e9-4e70-b7b9-41e8f35fcce6/the-tcpip-connection-to-the-host-127001-port-1433-has-failed?forum=sqldatabaseengine
# ip配置1433 https://stackoverflow.com/questions/18841744/jdbc-connection-failed-error-tcp-ip-connection-to-host-failed





# 查看版本
Select @@version


# 查看数据库编码: 936 简体中文GBK 950 繁体中文BIG5 437 美国/加拿大英语 932 日文 949 韩文 866 俄文 65001 unicode UFT-8
SELECT COLLATIONPROPERTY('Chinese_PRC_Stroke_CI_AI_KS_WS', 'CodePage');


# 查看所有collate字符排序规则(校对集)
SELECT * from ::fn_helpcollations();

# 服务器校对集
SELECT SERVERPROPERTY(N'Collation');

# 数据库(test)校对集
SELECT name, collation_name FROM sys.databases WHERE name = N'test';

# 表格校对集
SELECT object_id,name, collation_name FROM sys.columns WHERE object_id =OBJECT_ID('test');

# 更改数据库(test)校对集 (注意索引会有问题)
ALTER DATABASE test COLLATE Chinese_PRC_CS_AI;

# 注意索引会有问题
ALTER TABLE test ALTER COLUMN name VARCHAR(12) COLLATE Chinese_PRC_CI_AI;