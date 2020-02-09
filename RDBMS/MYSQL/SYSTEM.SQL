-- ================================ System(V5.1.7) ================================
-- 查看连接状态(比如说等待锁)
show processlist;

-- 查看mysql隔离级别
show variables like 'transaction_isolation';

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