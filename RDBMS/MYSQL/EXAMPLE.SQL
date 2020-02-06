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

/* 存储过程初始化数据 */
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