---------------------------------------- 1.模拟事务隔离一致性性现象 ----------------------------------------
CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `c` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
INSERT INTO t(id, c) VALUES(1,1),(2,2),(3,3),(4,4);

TRUNCATE t;
SELECT * FROM  t;
UPDATE t SET c = c + 1;
UPDATE t SET c = 0 WHERE id = c;


---------------------------------------- 2.模拟索引问题 ----------------------------------------
CREATE TABLE `t1` (
  `id` int(11) NOT NULL,
  `a` int(11) DEFAULT NULL,
  `b` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `a` (`a`),
  KEY `b` (`b`)
) ENGINE=InnoDB;

/* 存储过程初始化数据,临时设置0(全局需要重新连接mysql),执行完复原1 */
set global innodb_flush_log_at_trx_commit=0;
set global sync_binlog=0;
delimiter ;;
create procedure idata()
begin
  declare i int;
  set i=1;
  while(i<=100000)do
    insert into t1 values(i, i, i);
    set i=i+1;
  end while;
end;;
delimiter ;
call idata();
set global innodb_flush_log_at_trx_commit=1;
set global sync_binlog=1;

/* 测试索引选择 */
explain select * from t1 where a between 10000 and 20000;
explain select * from t1 force index(b) where a between 10000 and 20000;

/* 这里mysql优化器误选择了b索引,按照分析来看选择a索引仅仅需要扫描1000行,而b索引需要扫描50000,但是优化器认为order排序b */
/* 所以选择b索引可以省去排序,直接取数据.*/
explain select * from t1 where (a between 1 and 1000)  and (b between 50000 and 100000) order by b limit 1;

/* 强制索引b,但是不好维护,如果索引b改了名字,就需要改动语句 */
explain select * from t1 force index(b) where (a between 1 and 1000)  and (b between 50000 and 100000) order by b limit 1;

/* 利用sql语法规避,在保证查询结果相同的情况下,强制a,b索引都要排序,那么扫描行数成为关键 */
explain select * from t1 where (a between 1 and 1000)  and (b between 50000 and 100000) order by b,a limit 1;

/* limit 100这样优化器认为b索引的代价高(利用优化器的bug?) */
explain select * from(select * from t1 where (a between 1 and 1000)  and (b between 50000 and 100000) order by b limit 100)alias limit 1;


---------------------------------------- 3.测试order by ----------------------------------------
CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `city` varchar(16) NOT NULL,
  `name` varchar(16) NOT NULL,
  `age` int(11) NOT NULL,
  `addr` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `city` (`city`)
) ENGINE=InnoDB;
select city,name,age from t where city='杭州' order by name limit 1000;

/* extra字段: fileSort代表需要排序 */
explain select city,name,age from t where city='杭州' order by name limit 1000;

------------------使用optimizer_trace查看是否使用临时文件排序
/* 打开optimizer_trace，只对本线程有效 */
SET optimizer_trace='enabled=on';

/* @a保存Innodb_rows_read的初始值 */
select VARIABLE_VALUE into @a from  performance_schema.session_status where variable_name = 'Innodb_rows_read';

/* 执行语句 */
select city, name,age from t where city='杭州' order by name limit 1000;

/* 查看 OPTIMIZER_TRACE 输出 */
SELECT * FROM `information_schema`.`OPTIMIZER_TRACE`\G

/* @b保存Innodb_rows_read的当前值 */
select VARIABLE_VALUE into @b from performance_schema.session_status where variable_name = 'Innodb_rows_read';

/* 计算Innodb_rows_read差值 */
select @b-@a;

/* extra字段: 没有fileSort代表不需要排序,利用索引本身的有序性 */
alter table t add index city_user(city, name);
explain select city,name,age from t where city='杭州' order by name limit 1000;

/* extra字段: 没有fileSort代表不需要排序,同时多了using index利用索引本身的有序性排序,同时利用了索引覆盖取出age */
alter table t add index city_user_age(city, name, age);
explain select city,name,age from t where city='杭州' order by name limit 1000;

-- 随机
CREATE TABLE `words` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `word` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

delimiter ;;
create procedure wordsdata()
begin
  declare i int;
  set i=0;
  while i<10000 do
    insert into words(word) values(concat(char(97+(i div 1000)), char(97+(i % 1000 div 100)), char(97+(i % 100 div 10)), char(97+(i % 10))));
    set i=i+1;
  end while;
end;;
delimiter ;
call wordsdata();

-- 性能差不建议使用
explain select word from words order by rand() limit 3;

-- 测试:fileSort_priority_queue_optimization:chosen = true
set tmp_table_size=1024;
set sort_buffer_size=32768;
set max_length_for_sort_data=16;
SET optimizer_trace='enabled=on';
select word from words order by rand() limit 3;
SELECT * FROM `information_schema`.`OPTIMIZER_TRACE`\G

-- 随机方案1,数据页有空洞,每个id概率不一样
select max(id),min(id) into @M,@N from t ;
set @X= floor((@M-@N+1)*rand() + @N);
select * from t where id >= @X limit 1;

-- 随机方案2,(limit后面不可以跟参数,使用prepare+execute)
select count(*) into @C from t;
set @Y = floor(@C * rand());
set @sql = concat("select * from t limit ", @Y, ",1");
prepare stmt from @sql;
execute stmt;
DEALLOCATE prepare stmt;

-- 随机3(limit后面不可以跟参数,Y1、Y2、Y3值拼出SQL后执行)
select count(*) into @C from t;
set @Y1 = floor(@C * rand());
set @Y2 = floor(@C * rand());
set @Y3 = floor(@C * rand());
select * from t limit @Y1，1;
select * from t limit @Y2，1；
select * from t limit @Y3，1；



---------------------------------------- 4.测试函数破坏索引 ----------------------------------------

CREATE TABLE `tradelog` (
`id` int(11) NOT NULL,
`tradeid` varchar(32) DEFAULT NULL,
`operator` int(11) DEFAULT NULL,
`t_modified` datetime DEFAULT NULL,
PRIMARY KEY (`id`),
KEY `tradeid` (`tradeid`),
KEY `t_modified` (`t_modified`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `trade_detail` (
`id` int(11) NOT NULL,
`tradeid` varchar(32) DEFAULT NULL,
`trade_step` int(11) DEFAULT NULL,
`step_info` varchar(32) DEFAULT NULL,
PRIMARY KEY (`id`),
KEY `tradeid` (`tradeid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into tradelog values(1, 'aaaaaaaa', 1000, now());
insert into tradelog values(2, 'aaaaaaab', 1000, now());
insert into tradelog values(3, 'aaaaaaac', 1000, now());
insert into tradelog values(4, 'aaaaaaae', 1000, '2020-07-01');

insert into trade_detail values(1, 'aaaaaaaa', 1, 'add');
insert into trade_detail values(2, 'aaaaaaaa', 2, 'update');
insert into trade_detail values(3, 'aaaaaaaa', 3, 'commit');
insert into trade_detail values(4, 'aaaaaaab', 1, 'add');
insert into trade_detail values(5, 'aaaaaaab', 2, 'update');
insert into trade_detail values(6, 'aaaaaaab', 3, 'update again');
insert into trade_detail values(7, 'aaaaaaab', 4, 'commit');
insert into trade_detail values(8, 'aaaaaaac', 1, 'add');
insert into trade_detail values(9, 'aaaaaaac', 2, 'update');
insert into trade_detail values(10, 'aaaaaaac', 3, 'update again');
insert into trade_detail values(11, 'aaaaaaac', 4, 'commit');

-- 1.month函数(查找16,17,18年七月份的数量)
explain select count(*) from tradelog where month(t_modified) = 7;
-- 1.1优化,选择索引
select count(*) from tradelog where
(t_modified >= '2016-7-1' and t_modified<'2016-8-1')
or
(t_modified >= '2017-7-1' and t_modified<'2017-8-1')
or
(t_modified >= '2018-7-1' and t_modified<'2018-8-1');

-- 测试mysql字符串与数字比较时,是将字符串转换成数字: 结果是 3 > 1返回true:1
select "3" > 1;
-- 2.隐式类型转换varchar,导致CAST函数
explain select * from tradelog where tradeid = 110717;
select * from tradelog where  CAST(tradid AS signed int) = 110717;
-- 2.1优化
explain select * from tradelog where tradeid = '110717';


-- 3.隐式编码转换,小(utf8)转大(utf8mb4),导致CONVERT函数
explain select d.* from tradelog l, trade_detail d where d.tradeid=l.tradeid and l.id=2;
select * from trade_detail where tradeid=$L2.tradeid.value;
select * from trade_detail  where CONVERT(traideid USING utf8mb4)=$L2.tradeid.value;
-- 3.1 优化1(sql)
select d.* from tradelog l, trade_detail d where d.tradeid=CONVERT(l.tradeid USING utf8) and l.id=2;
-- 3.2 优化2(DDL)
alter table trade_detail modify tradeid varchar(32) CHARACTER SET utf8mb4 default null;

-- 4.索引字段没有隐式转换
select l.operator from tradelog l , trade_detail d where d.tradeid=l.tradeid and d.id=4;
select operator from tradelog  where traideid =$R4.tradeid.value;
select operator from tradelog  where traideid =CONVERT($R4.tradeid.value USING utf8mb4);



---------------------------------------- 5.测试查询一行语句,性能问题 ----------------------------------------
-- 1.A加了mdl锁,B去查询,就会等待A
-- a加锁
lock table t write;
-- b查询,堵塞
select * from t where id = 1;
-- 查看原因:Waiting for table metadata lock
show processlist;
-- 通过sys.performance_schema,查看具体锁进程id信息,performance_schema=on(10%左右性能损失),然后kill锁进程即可
select blocking_pid from schema_table_lock_waits;
kill 32;
-- performance_schema=on而且ENABLED='YES',TIMED='YES',才可以查看到上述的blocking_pid
show variables like 'performance_schema';
select * from performance_schema.setup_instruments where name='wait/lock/metadata/sql/mdl';
update performance_schema.setup_instruments set ENABLED='YES',TIMED='YES' where name='wait/lock/metadata/sql/mdl';

-- 2.flush被阻塞,进而阻塞select(三个线程)
select sleep(10000);
flush tables t;
select * from t where id =1;
-- 查询kill
show processlist;
kill id;

-- 3.读写行锁等待
begin; update t set c = c + 1 where id = 1;
-- 读取阻塞直到上一个commit
select * from t where id = 1 lock in share mode;
-- processlist看出阻塞,然后利用innodb_lock_waits查出pid杀死
show processlist;
select * from sys.innodb_lock_waits where locked_table = '`test`.`t`'\G;
-- kill id,不是kill query是停止当前执行的语句,但是update语句已经执行完,kill query无法释放锁
kill id;


-- 4.查询慢(线上超过1s的算是慢查询)
CREATE TABLE `t4` (
  `id` int(11) NOT NULL,
  `c` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

delimiter ;;
create procedure idata4()
begin
  declare i int;
  set i=1;
  while(i<=100000) do
    insert into t4 values(i,i);
    set i=i+1;
  end while;
end;;
delimiter ;

call idata4();





---------------------------------------- 6.加锁规则验证 ----------------------------------------
CREATE TABLE `t3` (
  `id` int(11) NOT NULL,
  `c` int(11) DEFAULT NULL,
  `d` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `c` (`c`)
) ENGINE=InnoDB;
insert into t3 values(0,0,0),(5,5,5), (10,10,10),(15,15,15),(20,20,20),(25,25,25);



-- 验证等值查询:首先是next-key lock:(5,10],然后退化成间隙锁(5,10)
-- a:(5,10]->退化(5,10)
begin; update t3 set d=d+1 where id=7;
-- b:blocked
insert into t3 values (8,8,8);
-- c:ok
update t3 set d=d+1 where id=10;
-- 查看锁信息:X(写锁,排他锁),GAP(间隙锁)
-- (注意设置 ENABLED='YES',TIMED='YES',同时锁等待时间大一些,否则默认50s等待,自动退出锁)
select * from sys.innodb_lock_waits where locked_table = '`test`.`t3`'\G;



-- 验证索引覆盖等值索引问题
-- a:首先是(0,5]间隙锁,c是普通索引,继续查找下一条数据c=10,这个时候加(5,10],然后退化(5,10)
begin; select id from t3 where c=5 lock in share mode;
-- b: 锁是加载索引上,因为查询id,直接在c索引上覆盖查出,所以id主键索引没有加锁,id=5可以更新
update t3 set d=d+1 where id=5;
-- c: 因为间隙锁(5,10),所以block
insert into t3 values(7,7,7);
-- 查看锁信息:S(读锁,共享锁),GAP(间隙锁)
-- (注意设置 ENABLED='YES',TIMED='YES',同时锁等待时间大一些,否则默认50s等待,自动退出锁)
select * from sys.innodb_lock_waits where locked_table = '`test`.`t3`'\G;



-- 验证锁是加在索引上
-- a:查询d没有覆盖索引,就需要访问主键索引,这个时候b去更新id=5就会被block
begin; select d from t3 where c=5 lock in share mode;
-- b;没有索引覆盖,就会访问到主键索引,访问到的对象加锁,这个时候block,而且是x写锁
update t3 set d=d+1 where id=5;
-- 查看锁信息:X(写锁,排他锁)
-- (注意设置 ENABLED='YES',TIMED='YES',同时锁等待时间大一些,否则默认50s等待,自动退出锁)
select * from sys.innodb_lock_waits where locked_table = '`test`.`t3`'\G;



-- 验证唯一索引范围查询(不退化成间隙锁,仍然是next-key lock),等值查询才会优化
-- a:首先是(5,10]等值退化成id=10的行锁,然后是范围查询,大于10的第一条是15也就是(10,15],此刻的锁是id=10和next-key
-- lock(10,15],因为是范围查询所以锁不发生退化
begin;select * from t3 where id>=10 and id<11 for update;
-- b:id=8插入成功,13的插入失败
insert into t3 values(8,8,8);
insert into t3 values(13,13,13);
-- c:因为是范围查询,不是等值查询,所以索引上的锁不退化,包含15这一行锁,所以block
update t3 set d=d+1 where id=15;



-- 验证普通索引的范围锁不退化,等值锁当不包含的时候才退化成间隙锁,当包含值且是唯一索引才退化成行锁
-- a:首先是(5,10],然后是范围查询,大于10的第一条是15也就是(10,15],此刻的锁是(5,10]和(10,15],没有对应的优化规则
begin;select * from t3 where c>=10 and c<11 for update;
-- b:id=8插入失败
insert into t3 values(9,9,9);
-- c:因为是范围查询,不是等值查询,所以索引上的锁不退化成间隙锁,包含15这一行锁,所以block
update t3 set d=d+1 where c=15;



-- 1.delete删除最好加上limit,减少所范围,同时安全性高,明确删除条数(c=10有两行)
insert into t3 values(30,10,30);
-- a:索引c上锁最终(5,10],(10,15)
begin; delete from t3 where c = 10;
-- b:block
insert into t3 values(12,12,12);
-- c:ok
update t3 set d=d+1 where c=15;

-- 1.1.delete删除最好加上limit,减少所范围,同时安全性高,明确删除条数(c=10有两行)
-- a:因为c=10一共就两行,所以扫描到的哥c=10就会停止扫描,索引c上锁最终(5,10],(10,10]也即是(5,10]
begin; delete from t3 where c = 10 limit 2;
-- b:ok
insert into t3 values(12,12,12);



-- 验证next-key lock是由间隙锁+行锁组成,实际执行的时候也是分成间隙锁和行锁两段来执行的
-- a:加上next-key lock(5,10]
begin; select * from t3 where c = 10 lock in share mode;
-- b:然后sessionB更新也需要加上next-key lock(5,10],分成两段,先是间隙锁(5,10)这个时候与a之间的间隙锁不冲突,但是加行锁10时,就要进入锁等待block
update t3 set d=d+1 where c= 10;
-- a:这个时候a又要插入,本身是可以插入,虽然b没有申请到next-key lock,但是已经申请了间隙锁(5,10)阻塞a的插入,所以ab之间相互等待出现死锁
-- ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
insert into t3 value(8,8,8);



-- 分析锁
-- a:由于order by先加的时c=20的next-key lock (15,20],然后范围向右,退化就是(20,25),然后向左遍历到c=10不退化,也即是(5,10],(10,15]整体上c索
-- 引上的锁范围:(5,25),又因为没有覆盖主键,回表导致主键加了三个行锁(10,15,20)
begin;select * from t3 where c>=15 and c<=20 order by c desc lock in share mode;
-- b:间隙锁(5,25)block
insert into t3 value(6,6,6);
insert into t3 value(16,16,16);

-- block
update t3 set d=d+1 where c=15;
update t3 set d=d+1 where id=15;
update t3 set d=d+1 where c=20;
update t3 set d=d+1 where id=20;
-- ok
update t3 set d=d+1 where id=25;
update t3 set d=d+1 where c=25;

-- block(由于向左不是向右导致锁不退化) ???
update t3 set d=d+1 where c=10;
-- ok ???
update t3 set d=d+1 where id=10;

