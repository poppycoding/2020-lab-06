---------------基于mysql5.7+---------------

-- 查看连接状态
show processlist;

-- 重新设置连接(不需要重连和权限认证),防止长连接过长,内存OOM导致mysql重启
mysql_reset_connection;

-- redo log是物理日志,只存在innodb引擎中,其他mysql引擎中不存在,binlog是逻辑日志,是mysql server层的实现,记录操作语句.
-- 设置redo log每一次事务都持久化到硬盘
innodb_flush_log_trx_commit = 1

-- 设置bin log每一次事务都持久化到硬盘
sync_binlog = 1

-- 事务隔离级别:
-- 读未提交(read uncommitted):
-- 读提交(read committed): 每个sql开始执行时创建视图(多个事务共享数据??)
-- 可重复读(repeatable read): 事务启动时创建试图,整个事务期间只使用这个试图(通过回滚日志实现??)
-- 串行化(serializable): 通过加锁方式实现,读写冲突时需要等待

-- 查看mysql隔离级别
show variables like 'transaction_isolation'

-- oracle默认隔离级别是'读提交',因此oracle迁移应用到mysql时,为了保证数据库隔离级别一致,需要设置MySQL启动参数
-- mysql默认是REPEATABLE-READ
transaction_isolation = READ_COMMITTED

-- 长事务,会保留这个事务中的任意数据,也即是老旧试图,会占用大量空间,同时占用锁资源,尽量避免长事务
-- 这个命令是关闭自动提交,当执行任意语句,默认就会开启一个事务(不需要显式begin),并且不自动提交,直到执行commit/rollback之前,这就是一个长事务
set autocommit = 0

-- 只有使用begin/start显式开启事务,然后使用commit提交,如果一个业务频繁使用事务,可以使用commit work and chain代替commit
-- 表示提交这个事务,并且启动下一个事务,省去主动执行begin/start的语句交互
set autocommit = 1

-- 查找超过60s的事务
SELECT * FROM information_schema.innodb_trx WHERE TIME_TO_SEC(TIMEDIFF(NOW(),trx_started)) > 60;


------------------------------------- 索引 -------------------------------------
-- 主键索引:聚簇索引(clustered index)叶子节点存的是整行数据,主键查询方式,只需要查询这一颗B+
-- 普通索引:二级索引(secondary index),叶子节点存的是主键值,查询时需要先查一次普通索引树,获取到主键值,然后进行回表操作,去主键树查询数据
-- B+树维护:当数据页数据满的时候(中间插入数据造成的数据页满载,递增造成满载不会发生也分裂),发生页分裂,影响性能,同时空间利用
-- 率降低(刚满的时候平分到两个数据页),当新增数据时,依次递增是最好的情况,索引树不需要挪动,只需要往后追加,这也是建议使用自增id
-- 作为主键的原因,避免插入的主键落入中间位置,后续的数据都要做出偏移,同时也不会触发页分裂;而业务逻辑字段不容保证有序插入,同时
-- 非主键索引的叶子都是主键值,那么主键值字节数越小,整体空间就越小,而自增id往往是int/bigint比string等其他业务字段节省空间.

-- 使用业务字段做主键的场景:只有一个索引,且是唯一索引,这个时候考虑主键索引

-- 索引优化:本质上都是减少回表操作
-- 1.覆盖索引:例如根据k查询主键id的时候,下面的语句,不需要回表操作,因为k索引树中的叶子节点上就是id主键值,减少回表,树的搜索次数
--          同时根据业务场景,利用联合索引实现覆盖索引,也可以减少回表操作.
SELECT * FROM t WHERE k BETWEEN 3 AND 5;
SELECT id FROM t WHERE k BETWEEN 3 AND 5;

-- 2.最左前缀:建立联合索引时候,第一原则是通过调整顺序实现最左原则,可以减少维护一个索引,当既有联合索引同时都涉及到各自的单独索引
--          这个时候空间原则有限,选择字段长度小的单独索引,大的作为联合索引:如 a>b 则联合索引(a,b),单独索引b

-- 3.索引下推:mysql5.6+引入了pushDown下推优化,当联合索引中的字段都在条件中时,会对第二个字段做出过滤,如:联合索引(author,age)
--          这个时候使用索引获取author是F开头的,然后进一步判断联合索引中的age字段做出过滤,5.6之前的版本不会对age字段做
--          过滤,会查出所有F开头的主键,然后逐个去主键B+中比对,而5.6之后会优先过滤出age字段,减少去主键B+的回表操作.
SELECT * FROM t WHERE author LIKE %F% AND age > 10;


