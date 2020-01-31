---------------------------------------- 1.模拟事务隔离一致性性现象
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


---------------------------------------- 2.模拟索引问题
CREATE TABLE `t1` (
  `id` int(11) NOT NULL,
  `a` int(11) DEFAULT NULL,
  `b` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `a` (`a`),
  KEY `b` (`b`)
) ENGINE=InnoDB;

-- 存储过程初始化数据
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

-- 测试索引选择
explain select * from t1 where a between 10000 and 20000;
explain select * from t1 force index(b) where a between 10000 and 20000;

-- 这里mysql优化器误选择了b索引,按照分析来看选择a索引仅仅需要扫描1000行,而b索引需要扫描50000,但是优化器认为order排序b,
--   所以选择b索引可以省去排序,直接取数据.
explain select * from t1 where (a between 1 and 1000)  and (b between 50000 and 100000) order by b limit 1;
-- 强制索引b,但是不好维护,如果索引b改了名字,就需要改动语句
explain select * from t1 force index(b) where (a between 1 and 1000)  and (b between 50000 and 100000) order by b limit 1;
-- 利用sql语法规避,在保证查询结果相同的情况下,强制a,b索引都要排序,那么扫描行数成为关键
explain select * from t1 where (a between 1 and 1000)  and (b between 50000 and 100000) order by b,a limit 1;
-- limit 100这样优化器认为b索引的代价高(利用优化器的bug?)
explain select * from(select * from t1 where (a between 1 and 1000)  and (b between 50000 and 100000) order by b limit 100)alias limit 1;
