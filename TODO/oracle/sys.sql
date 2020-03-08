
--1.查看table创建(最后更新)时间
select CREATED(LAST_DDL_TIME) from ALL_OBJECTS where OBJECT_TYPE='TABLE' and OBJECT_NAME= your_table_name;



--2.利用expdp ,impdp导入导出时的逻辑目录sql
create directory exp_dir as '/home/oracle';
-- 查看是否创建成功
select * from dba_directories;
-- 该目录授权给所有人(或者指定用户to some user)
grant read,write on directory exp_dir to public;



--3.查看数据库[表格-视图-列(table+view)]数量
--user_tables(当前登陆)
select count(*) from user_tables;
select count(*) from user_views;
select count(column_name) from user_tab_columns [where table_name = 'TEST'];
--dba_tables(dba权限)
select count(*) from dba_tables where owner='TEST';
select count(*) from dba_views where owner = 'TEST'
select count(column_name) from dba_tab_columns [where owner='TEST'];
--all_tables(dba权限)
select count(*) from all_tables where owner='TEST';
select count(*) from all_views where owner = 'TEST';
select count(column_name) from all_tab_columns [where owner='TEST'];



--4.查看schema下所有: 数据库+表格+视图+列数量
SELECT
t.table_num, v.view_num, c.column_num, (t.table_num + v.view_num + c.column_num + 1) count_all
FROM
(select count(*) table_num from dba_tables where owner='CTMSPROD') t,
(select count(*) view_num from dba_views where owner = 'CTMSPROD') v,
(select count(column_name) column_num from dba_tab_columns where owner='CTMSPROD') c




--5.表空间
--创建:create tablespace 表间名 datafile '数据文件名' size 表空间大小 autoextend 自动扩展 unlimited 无限制
create tablespace data_test datafile '/oracle/app/oradata/orcl/data_test_tbs.dbf' size 100M autoextend on next 10M maxsize unlimited;
--追加表空间:
alter tablespace PDW_XCGT add datafile '/oradata/neworcl/PDW_XCGT11.dbf' size 1G autoextend on maxsize 16g;
--直接追加到最大(文件最大32g)
alter tablespace PDW_XCGT add datafile '/oradata/neworcl/PDW_XCGT_max_1.dbf' size 30g autoextend off;
--清空回收站
purge recyclebin
--查看
SELECT tablespace_name, file_id, file_name, round(bytes / (1024 * 1024), 0) total_space FROM dba_data_files ORDER BY tablespace_name;



--6.oracle相关操作
--[创建用户]:create user 用户名 identified by 口令[即密码]；
create user username identified by pwd;
--[创建默认表空间的用户] create user 用户名 identified by 密码 default tablespace 表空间表;
create user username identified by pwd default tablespace data_test;
--[删除用户]:drop user 用户名 cascade(如果有数据对象,必须加上cascade参数);
drop user test cascade;


--oracle为兼容以前版本，提供三种标准角色（role）:connect(临时)/resource(正式)/dba(管理员).
--授权：grant connect, resource to 用户名
grant connect, resource to test;
--撤销：revoke connect, resource from 用户名;
revoke connect, resource from test;


--用户还可以在oracle创建自己的role(需要拥有create role系统权限)
--创建
create role testRole;
--拥有testRole角色的所有用户都具有对class表的select查询权限
grant select on class to testRole;
--删除角色,相关的权限将从数据库全部删除
drop role testRole;





--7.oracle查看表空间情况
SELECT Upper(F.TABLESPACE_NAME)         "表空间名",
       D.TOT_GROOTTE_MB                 "表空间大小(M)",
       D.TOT_GROOTTE_MB - F.TOTAL_BYTES "已使用空间(M)",
       To_char(Round(( D.TOT_GROOTTE_MB - F.TOTAL_BYTES ) / D.TOT_GROOTTE_MB * 100, 2), '990.99')
       || '%'                           "使用比",
       F.TOTAL_BYTES                    "空闲空间(M)",
       F.MAX_BYTES                      "最大块(M)"
FROM   (SELECT TABLESPACE_NAME,
               Round(Sum(BYTES) / ( 1024 * 1024 ), 2) TOTAL_BYTES,
               Round(Max(BYTES) / ( 1024 * 1024 ), 2) MAX_BYTES
        FROM   SYS.DBA_FREE_SPACE
        GROUP  BY TABLESPACE_NAME) F,
       (SELECT DD.TABLESPACE_NAME,
               Round(Sum(DD.BYTES) / ( 1024 * 1024 ), 2) TOT_GROOTTE_MB
        FROM   SYS.DBA_DATA_FILES DD
        GROUP  BY DD.TABLESPACE_NAME) D
WHERE  D.TABLESPACE_NAME = F.TABLESPACE_NAME
ORDER  BY 1





--8.强制删除用户时,kill用户相关连接
select 'alter system kill session '||''''||sid||','||serial#||''''||';' from v$session where username='PSPRD';





--9.创建序列:MY_SE从1开始每次自增1
--创建序列
CREATE SEQUENCE MY_FIRST_SEQ
MINVALUE 1
NOMAXVALUE
INCREMENT BY 1
START WITH 1 NOCACHE;

--手动插入模式,需要id手动触发
insert into MY_FIRST(id,comment) values(MY_FIRST_SEQ.NEXTVAL,'注释');

--触发器模式
create or replace trigger T_MY_FIRST_ID_TRIGGER
  before insert on MY_FIRST
  for each row
begin
  select MY_FIRST_SEQ.nextval into :new.id from dual;
end T_MY_FIRST_ID_TRIGGER;
--不需要id,自动触发生成
insert into MY_FIRST(comment) values('注释');

--注意同一次会话(执行完insert之后执行下列语句即可),可直接获取序列值
SELECT MY_FIRST_SEQ.currval FROM DUAL






--10.分页查询: oracle分页不像mysql和sqlserver那么简单，mysql有limit函数，sqlserver有top关键字，oracle没有,必须借助伪列rownum
-- 每页显示10条分页
select * from
(
select rownum rm, t.*  from t_user t
) tm
where rm > 10 and rm <= 20

-- 换成代码形式
select * from
(
select rownum rm, t.*  from t_user t
) tm
where rm > pageSize * ( pageNow - 1 ) and rm <= pageSize * pageNow

-- 有orderBy需要再嵌套一层???



-- 查看服务端编码 AL32UTF8
select * from nls_database_parameters where parameter ='NLS_CHARACTERSET';

-- 查看客户端编码 SIMPLIFIED CHINESE
select * from nls_instance_parameters where parameter='NLS_LANGUAGE';