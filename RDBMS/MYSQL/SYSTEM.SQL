-- ================================ System(V5.1.7) ================================
-- 查看连接状态(比如说等待锁)
show processlist;

-- /G的作用是将查到的结构旋转90度变成纵向
select * from t\G;

-- 查看磁盘IOPS,方便设置innodb_io_capacity
-- win查看C盘(自行装在fio软件)
fio -filename=C: -direct=1 -iodepth=1 -thread -rw=randrw -ioengine=windowsaio -bs=16k -size=5g -numjobs=10 -runtime=1000 -group_reporting -name=mytest
-- linux查看/home/data
fio -filename=/home/data -direct=1 -iodepth=1 -thread -rw=randrw -ioengine=psync -bs=16k -size=500M -numjobs=10 -runtime=10 -group_reporting -name=mytest

-- 计算db的脏页比例
select VARIABLE_VALUE into @a from performance_schema.global_status where VARIABLE_NAME = 'Innodb_buffer_pool_pages_dirty';
select VARIABLE_VALUE into @b from performance_schema.global_status where VARIABLE_NAME = 'Innodb_buffer_pool_pages_total';
select @a/@b;

-- 重新计算索引基数
analyze table t;

-- 重建表
alter table t engine = InnoDB;

-- 重建索引+重建表
optimize table t;

-- 查看数据库表的概况,其中rows并不是确切行数
show table status;

-- 查看参数var的值
show variables like 'var'
-- 设置参数var值,默认是当前线程,global是全局
set var = value;
set global var = value;

-- 查看mysql隔离级别
show variables like 'transaction_isolation';

-- 修改排序rowid算法的的因子
show variables like 'max_length_for_sort_data';
show variables like 'sort_buffer_size';
show variables like 'tmp_table_size';
-- 设置当前连接的大小
set max_length_for_sort_data = 2048;
set sort_buffer_size = 2097152;
-- 设置全局大小
set global max_length_for_sort_data = 2048;
set global sort_buffer_size = 2097152;

-- 查看sys.performance_schema是否开启,方便监控性能问题,但是开启后有10%左右性能损失
show variables like 'performance_schema';

-- 开启锁信息记录:ENABLED='YES',TIMED='YES',否则无法查看blocking_pid
select * from performance_schema.setup_instruments where name='wait/lock/metadata/sql/mdl';
update performance_schema.setup_instruments set ENABLED='YES',TIMED='YES' where name='wait/lock/metadata/sql/mdl';

-- 查看阻塞的锁pid,方便kill
select blocking_pid from sys.schema_table_lock_waits;
kill pid;

-- 手动flush表,可以指定某一张表,不指定是全库的表,flush的时候会加read lock,相当于关闭表,这个时候查询阻塞
flush tables;
flush tables t;

-- 查看死锁设置时间,设置当前线程死锁时间
show variables like 'innodb_lock_wait_timeout';
set innodb_lock_wait_timeout=10000;

-- 查看表的锁信息
select * from sys.innodb_lock_waits\G;
-- 查看数据库test中的t表的当前锁信息,注意单引号''和反引号``
select * from sys.innodb_lock_waits where locked_table = '`test`.`t`'\G;

-- 临时设置成0,默认是1,可以提高性能(这两个是global变量,必须加global),全局参数需要重新连接mysql才生效
show variables like 'sync_binlog';
show variables like 'innodb_flush_log_at_trx_commit';
set global innodb_flush_log_at_trx_commit=0;
set global sync_binlog=0;

-- 查看你自定义存储过程和函数
select name from mysql.proc where db='test' and type='FUNCTION';
select name from mysql.proc where db='test' and type='PROCEDURE';

-- 删除存储过程/函数: DROP { PROCEDURE | FUNCTION } [ IF EXISTS ] <name>
drop PROCEDURE if EXISTS my-procedure-name;