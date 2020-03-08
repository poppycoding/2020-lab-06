#!/usr/bin/env bash
# 进入oracle命令行
sqlplus / as sysdba


# oracle用户相关操作
# 语法[创建用户]:create user 用户名 identified by 口令[即密码]；
create user username identified by pwd;
# 语法[删除用户]:drop user 用户名 cascade(如果有数据对象,必须加上cascade参数);
drop user test cascade;



# oracle为兼容以前版本，提供三种标准角色（role）:connect(临时)/resource(正式)/dba(管理员).
# 授权语法：grant connect, resource to 用户名
grant connect, resource to test;
# 撤销语法：revoke connect, resource from 用户名;
revoke connect, resource from test;



# 用户还可以在oracle创建自己的role(需要拥有create role系统权限)
# 语法:create role 角色名;
create role testRole;
# 拥有testRole角色的所有用户都具有对class表的select查询权限
grant select on class to testRole;
# 删除角色,相关的权限将从数据库全部删除
drop role testRole;

to_char
to_date
to_number

# nvl函数基本语法为nvl(E1,E2)，意思是E1为null就返回E2，不为null就返回E1。
# nvl2函数的是nvl函数的拓展，基本语法为nvl2(E1,E2,E3)，意思是E1为null，就返回E3，不为null就返回E2。


# ESCAPE: 自定义一个转义字符,这个字符的字符原样匹配不作为通配符号使用
ESCAPE 'escape_character'
#  / 定义斜杆转义
SELECT * FROM A WHERE NAME LIKE '%A/%B%' ESCAPE '/'
#  ! 定义叹号转义
SELECT * FROM A WHERE NAME LIKE '%A!%B%' ESCAPE '!'









#





































#用expdp导出dmp，有五种导出方式：
#第一种：“full=y”，全量导出数据库；
expdp user/passwd@orcl dumpfile=expdp.dmp directory=data_dir full=y logfile=expdp.log;

#第二种：schemas按用户导出；
expdp user/passwd@orcl schemas=user dumpfile=expdp.dmp directory=data_dir logfile=expdp.log;

#第三种：按表空间导出；
expdp sys/passwd@orcl tablespace=tbs1,tbs2 dumpfile=expdp.dmp directory=data_dir logfile=expdp.log;

#第四种：导出表；
expdp user/passwd@orcl tables=table1,table2 dumpfile=expdp.dmp directory=data_dir logfile=expdp.log;

#第五种：按查询条件导；
expdp user/passwd@orcl tables=table1='where number=1234' dumpfile=expdp.dmp directory=data_dir logfile=expdp.log;


#用impdp命令导入，对应五种方式：
#第一种：“full=y”，全量导入数据库；
impdp user/passwd directory=data_dir dumpfile=expdp.dmp full=y;

#第二种：同名用户导入，从用户A导入到用户A；
impdp A/passwd schemas=A directory=data_dir dumpfile=expdp.dmp logfile=impdp.log;

#第三种：
#①从A用户中把表table1和table2导入到B用户中；
impdp B/passwdtables=A.table1,A.table2 remap_schema=A:B directory=data_dir dumpfile=expdp.dmp logfile=impdp.log;

#②将表空间TBS01、TBS02、TBS03导入到表空间A_TBS，将用户B的数据导入到A，并生成新的oid防止冲突；
impdp A/passwdremap_tablespace=TBS01:A_TBS,TBS02:A_TBS,TBS03:A_TBS remap_schema=B:A FULL=Y transform=oid:n directory=data_dir dumpfile=expdp.dmp logfile=impdp.log

#第四种：导入表空间；
impdp sys/passwd tablespaces=tbs1 directory=data_dir dumpfile=expdp.dmp logfile=impdp.log;

#第五种：追加数据table_exists_action:导入对象已存在时执行的操作。有效关键字:SKIP,APPEND,REPLACE和TRUNCATE
impdp sys/passwd directory=data_dir dumpfile=expdp.dmp schemas=system table_exists_action=replace logfile=impdp.log;

