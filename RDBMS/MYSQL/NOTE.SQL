---------------基于mysql5.7+---------------


-- 重新设置连接(不需要重连和权限认证),防止长连接过长,内存OOM导致mysql重启
mysql_reset_connection;

-- redo log是物理日志,只存在innodb引擎中,其他mysql引擎中不存在,binlog是逻辑日志,是mysql server层的实现,记录操作语句.
-- 设置redo log每一次事务都持久化到硬盘
innodb_flush_log_trx_commit = 1

-- 设置bin log每一次事务都持久化到硬盘
sync_binlog = 1


-- mysql的两种视图
-- 1.view:利用create语法结合查询语句结果集生成的虚拟表.
-- 2.consistent read view:一致性视图,是多版本并发控制(MVCC)用得到一致性视图,用于实现读提交read-committed,
-- 可重复读repeatable-read的两种隔离级别.





------------------------------------- TRANSACTION -------------------------------------
-- 读未提交(read uncommitted):
-- 读提交(read committed): 每个sql开始执行时创建视图(多个事务共享数据??)
-- 可重复读(repeatable read): 事务启动时创建视图(MVCC视图),整个事务期间只使用这个试图(通过回滚日志实现??)
-- 串行化(serializable): 通过加锁方式实现,读写冲突时需要等待

-- 对于可重复读,查询只承认在事务启动前已经提交的数据,而读提交,只承认在语句启动前已经提交的数据


-- oracle默认隔离级别是'读提交',因此oracle迁移应用到mysql时,为了保证数据库隔离级别一致,需要设置MySQL启动参数
-- mysql默认是REPEATABLE-READ
transaction_isolation = READ_COMMITTED

-- 长事务,会保留这个事务中的任意数据,也即是老旧试图,会占用大量空间,同时占用锁资源,尽量避免长事务
-- 这个命令是关闭自动提交,当执行任意语句,默认就会开启一个事务(不需要显式begin),并且不自动提交,直到执行commit/rollback之前,这就是一个长事务
set autocommit = 0

-- 只有使用begin/start显式开启事务(如果没有显式开启则自动提交??),然后使用commit提交,如果一个业务频繁使用事务,可以使用
-- commit work and chain代替commit表示提交这个事务,并且启动下一个事务,省去主动执行begin/start的语句交互
set autocommit = 1

-- 查找超过60s的事务
SELECT * FROM information_schema.innodb_trx WHERE TIME_TO_SEC(TIMEDIFF(NOW(),trx_started)) > 60;

-- begin/start如下的命令并不是事务的起点,直到执行第一个sal语句才会真正开启事务.
begin/start transaction
-- start ..如下是立刻开启一个事务(注意,这是创建一个持续整个事务的一致性快照,但是如果数据库隔离级别时读提交,那就相当于普通的开启事务,等价于上面的效果)
start transaction with consistent snapshot

-- InnoDB是为每个事务创建一个数组记录未提交的事务id,通过记录最小id低水位,以及系统最大id加1记作高水位,组成一致性视图,通过
-- 对比事务id和这个一致性视图得到版本的可见性.

-- mysql多版本数据(一致性视图),除了自己的更新是可见以外,还有三种情况:
-- 1.版本未提交,不可见
-- 2.版本已提交,但是是在视图创建后提交的,不可见
-- 3.版本已提交,而且是在视图创建前提交的,可见

-- 当前读:多数据版本可见性规则,除了上述,还有一条是当前读,即:更新数据都是先读后写,而这个读,只能读当前的值.
-- 除了update语句当前读,当select语句加锁时,也是当前读,如下分别读锁(S锁,共享锁),写锁(X锁,排他锁)
SELECT k FROM t WHERE id = 1 LOCK IN SHARE MODE;
SELECT k FROM t WHERE id = 1 FOR UPDATE;





------------------------------------- INDEX -------------------------------------
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


-- 普通索引和唯一索引
-- 1.查询性能:普通索引查询时,当查到k=5时,需要继续对比下一个记录,直到不等于5;唯一索引因为唯一性,查到k=5时就会停止搜索;因为InnoDb
--         时按数据页为单位来读写的,所以不考虑特殊情况,比如k=5在数据页的最后一条,那么普通索引需要重新读取下一页数据,正常情况
--         下,k=5左右的数据都在同一个数据页,那么普通索引的多做的一次检索,只是内存中一次指针寻找和对比,所以与唯一索引多出来
--         的这次检索性能微乎其微,因此两者两者查询性能一致.
SELECT id FROM t WHERE k = 5;

-- 2.更新性能:
-- 2.1:要更新的目标页在内存中,那么普通索引和唯一索引性能几乎一致,普通索引是直接更新到内存,而唯一索引只是先判断一下唯一冲突,
--     然后更新到内存,事务完成,后台有进程merge更新,最后刷回物理数据.
-- 2.2:要更新的目标不再内存中,那么普通索引性能更好,因为唯一索引需要先读取数据页到内存,这就涉及到磁盘操作随机IO访问,这是数据库
--     成本最高的操作,而普通索引只是更新到change buffer中,减少了磁盘的随机访问.

-- change buffer:当有更新操作时,如果要更新的数据页恰好在内存中,则直接更新,如果不在内存中,正常情况下需要读取所需的数据页到
--       内存中,但是change buffer机制是把更新语句缓存在buffer中,等到下次有查询语句执行读取数据页时,再更新实际内容,这也
--       就是merge过程,同时后台线程也会定时merge,数据库正常shutdown过程中,也会执行merge操作,这也就相当于批量执行的效果
--       减少了读磁盘的次数,提高了语句执行速度,同时读入内存时要占用buffer pool,所以一定程度可以提高内存利用率.(唯一索引在
--       执行前会先判断是否违反唯一性约束,会首先读取对应的数据页到内存,既然肯定会读取数据页,那么就直接更新数据,就没必要change
--       buffer机制,因此只有普通索引可以使用,当然buffer也是用使用buffer pool的内存,因此也不能无限增大,如下参数设置表示
--       最多占用50%)
innodb_change_buffer_max_size = 50

-- change buffer是在merge的时候真正更新数据,因此merge之前缓存的变更记录越多,收益就越大,因此对于写多读少的业务场景比较好,
--       常见的就是账单类,日志类系统,而相反的是更新之后就需要查询的场景,则会立刻触发merge过程,这种不会减少随机访问IO次数,反
--       而增加了维护buffer的代价,这种业务场景下就不适用了,应该关闭change buffer机制.


-- 对索引字段做函数操作,会破坏索引值的有序性,因此优化器就决定放弃走树搜索功能(但是仍然选则小的索引树去遍历,不是根据B+树定位)
-- 1.显式的函数(month):直接加在索引字段上,破坏索引值,全表扫描
select count(*) from tradelog where month(t_modified)=7;

-- 2.隐式的类型转换:`tradeid` varchar(32),搜索的值是int类型
--  mysql比较字符串和数字的时候,默认是字符串转数字,结果是3 > 1返回true:1
select "3" > 1;
select * from tradelog where tradeid = 110717;
select * from tradelog where  CAST(tradid AS signed int) = 110717;
-- 优化:选择对应的的索引类型
select * from tradelog where tradeid = '110717';

-- 3.隐式的字符编码转换,小(utf8)转大(utf8mb4),导致CONVERT函数,驱动表l,被驱动表d
select d.* from tradelog l, trade_detail d where d.tradeid=l.tradeid and l.id=2;
-- 等价于被驱动表的操作
select * from trade_detail where tradeid=$L2.tradeid.value;
-- tradelog的字符集是mb4
select * from trade_detail  where CONVERT(traideid USING utf8mb4)=$L2.tradeid.value;
-- 3.1 优化1(sql层面)
select d.* from tradelog l, trade_detail d where d.tradeid=CONVERT(l.tradeid USING utf8) and l.id=2;
-- 3.2 优化2(DDL层面)
alter table trade_detail modify tradeid varchar(32) CHARACTER SET utf8mb4 default null;





------------------------------------- LOCK -------------------------------------
----------- 库级别锁:
-- 1.mysql提供了一种全局读锁(FLWRL),让整个数据库处于只读状态(不能有其他更新等操作),典型应用场景就是做全库的逻辑备份.
flush tables with read lock

-- 2.mysqldump使用参数single-transaction可以开启一致性事务,等同于可重复读的事务隔离级别,使用的是一致性视图,不影响
--   其他数据更新,但是要求是全库的所有表都要支持这个事务的隔离级别,比如MyISAM就不支持事务,因此不能使用.

--3.设置readonly参数可以让全库进入只读状态,但是缺点是当客户端出现异常是,数据库仍然保持readonly状态,而flwrl能自动释放全局锁
set global readonly = true

----------- 表级别锁:
-- 1.表锁,使用lock tables .. read/write语法实现,使用unlock tables解锁;如下,作用是限制其他线程写1,读写2,但是当前线程
--   也只能读1,读写2,不允许访问其他表,在没有出现行级锁之前,这种控制并发访问的粒度较大,影响面较广.
lock tables t1 read, t2 write;
unlock tables;

-- 2.另外一种是MDL(meta data lock)不需要显示使用,mysql5.5+引入,在访问一个表的时候会自动加上对应的读锁,写锁;避免当一个
--   线程读取数据时,另外一个线程修改了表结构,这样读取的数据就会与表结构不对应.读锁之间不互斥,读写锁以及写锁之间互斥,因此当执行
--   长事务的时候,另外的线程申请修改表结构等写锁会阻塞直到前一个事务执行完,这时第三个线程继续申请读锁,这个时候会阻塞直到写锁
--   完成释放,如果这个时候频繁请求读锁,会造成数据库线程爆满而挂掉.

-- 因此修改表结构要注意,长事务问题,查询innodb_trx表查看长事务kill掉,同时也根据数据库支持情况结合alisql的wait等语法尝试
-- 设置等待时间,一定时间内如果可以获取写锁就正常执行,否则就释放这个写锁,不阻碍后续的读锁,之后再不断尝试重复执行语句.
ALTER TABLE t NOWAIT ADD COLUMN ...;
ALTER TABLE t WAIT N ADD COLUMN ...;

----------- 行级别锁:
-- 1.innodb引擎支持行级别,MYISAM不支持;行锁是需要的时候才加上,但是不并不是执行完立刻释放,必须等事务结束才释放.
--   两阶段锁协议:行锁需要等待事务结束才释放,eg:一个事物中更新两行数据,第一行更新完不会释放第一个行锁,必须等等二行结束,同时
--   事务提交之后才释放这个两个行锁.因此当出现并发更新同一行的业务时,一定要将事务中其他不涉及并发的sql先执行,而涉及并发更新
--   同一行,就会竞争行锁,因此放到事务的最后执行,减少等待锁的时间.

-- 2.死锁,当出现循环依赖时发生死锁,eg:事务a执行更新id为1的语句时,事务b更新id为2的语句,紧接着事务a又申请更新id为2,事务b申请
--   更新id为1,这时事务a,b发生循环依赖发生死锁.
-- 2.1死锁超时策略:默认50s,等待超过50s第一个线程会超时退出,释放锁;但是这个超时时间过长,对于线上服务不可接受,同时又不能设置过
--   小,因为正常的不是死锁的业务可能被提前释放,造成误伤.
innodb_lock_wait_timeout = 50
-- 2.2死锁检测策略:默认开启,主动检测死锁当发现死锁的时候,回滚某一个线程事务;但是检测死锁的性能消耗较大,因为每发生一个事务被锁,
--   就要发起检测,假设1000个并发同时更新,那么死锁检测就是100w次,最终cpu爆炸.
indodb_deadlock_detect = on
-- 2.3因此死锁处理要具体看业务适当选择,如果确保业务没有死锁可以关掉死锁检测,同时可以考虑正常开启死锁检测,但是手动控制并发量,例如
--   通过中间件实现,也可以考虑将热点行数据分散到多行处理等


-- mysql设置慢查询,win10在my.ini配置文件中添加如下配置:
-- # 表示日志存储的方式.FILE将日志存入文件,默认是FILE,另外可以取值TABLE,表示将日志存入数据库表,当然也可以两者都选择,
-- # 配成FILE,TABLE.需要注意的是将日志记录到数据库表中,需耗费更多的系统资源,建议优先记录到文件.
log-output=FILE
-- # 当配置将日志记录到文件中时,这个参数可以指定文件名,默认路径在配置文件的同级的data目录下.
slow_query_log_file="slow.log"
-- # 慢查询日志的开关,1表示开启,0表示关闭
slow-query-log=1
-- # 慢查询日志的阈值,花费时间超过这个值的sql语句才会被记录,单位是秒
long_query_time=0

-- force index(a):强制使用索引a
SELECT * FROM t1 force index(a) where a between 1000 and 2000;


-- 查看索引信息,其中cardinality就是基数,代表索引的区分度,也就是索引上的不同值,越大越好.索引基数是mysql抽样计算出来的,默认
--   选择n个数据页,计算页面上的不同值,乘以这个这个索引的页面数就得到索引的基数,表的数据会持续更新,索引信息会等到变更的行数
--   超过1/m的时候重新做索引统计.
show index from t1;
-- 1.参数on表示统计信息持久化到内存:n=20,m=10.
-- 2.参数off表示统计信息储存在内存中:n=8,M=16.
innodb_stats_persistent = ON/OFF

-- 重置索引统计信息
analyze table t1;

-- mysql是优化器来统计要扫描的行数,explain中的rows就是优化器计算的sql执行扫描行数,有时候会选错索引,计算出来的行数就会有问题
--   通常优化器选择扫描行数较少的执行方案,但是具体还会考虑到回表操作,最终得出是使用主键索引还是是用普通索引.

-- 绝大对数优化器都能找到正确的索引,对于少数误判索引,以及索引选择异常解决(参考EXAMPLE.SQL案例):
-- 1.通过analyze语法可以重新统计索引信息；
-- 2.强制制定index(但是如果索引名字变更,后续不好维护)
-- 3.利用sql语法在保证结果集不变的情况下,诱导优化器选择选择索引
-- 4.尝试删除索引,而选择新建一个更合适的索引


-- 字符串索引场景id_card
-- 1.index(id_card)-直接创建完整索引,缺点是占用空间
-- 2.index(id_card(6))-创建前缀索引,节省空间,但是会增加扫描次数,同时不能使用覆盖索引
-- 3.reverse(id_card)-利用reverse函数倒叙存储,再创建浅醉索引,例如身份证号码,相同城市前几位相同
-- 4.crc32(id_card)-添加hash字段,利用hash函数值(长度短)作为索引,因为有hash碰撞,所以查询条件还是需要id_card值的校验
--   缺点:和倒叙存储一样,不支持范围扫描,同时额外调用数据库函数有性能消耗.
SELECT * FROM t WHERE id_card_crc = crc32(id_card_param) AND id_card = id_card_param





------------------------------------- Gap Lock -------------------------------------
-- 幻读:指一个事务在前后两次查询同一个范围的时候,后一次查询看到了前一次查询没有看到的行.
--  1.在可重复读隔离级别下,普通的查询时快照读,是不会看到别的事务插入的数据,因此幻读是在当前读下才会出现,eg: for update
begin; select * from t where d=5 for update; commit;
--  2.幻读专指看到新插入的行,更新的行不算,eg: for update的时候,另外一个线程更新某一行了d=5,此刻就会比更新前多看到这一行,
--  但是这个不是幻读,必须是新插入了一行,因为for update当前读,看到了插入的行才是幻读.

-- 假设存在幻读,新增的数据会产生一致性问题(binlog记录的顺序问题),因为锁不到未来新增的行,最终binlog记录的顺序就会导致数据
-- 不一致,如下:
-- 线程a
begin; select * from t where d=5 for update;
-- 线程b,插入之后更新c=5,直接提交,记录binlog:1,5,5
insert into t values(1,1,5); /*(1,1,5)*/
update t set c=5 where id=1; /*(1,5,5)*/
-- 线程a,提交记录binlog
update t set d=100 where d=5;/*所有d=5的行，d改成100*/
commit;

-- 最终binlog按照提交顺序,按照如下备份恢复出来的结果id=1新增的行就不是1,5,5而是1,5,100,这就造成了数据一致性问题,而锁的设
-- 计就是为了保证数据的一致性,不止是数据库内部数据状态一致,而且包含了数据和日志逻辑上的一致性
insert into t values(1,1,5); /*(1,1,5)*/
update t set c=5 where id=1; /*(1,5,5)*/
update t set d=100 where d=5;/*所有d=5的行，d改成100*/

-- GapLock: 产生幻读的原因就是行锁只能锁住行,但是新插入的的记录是在行之间的间隙,也即是两条记录之间的间隙,为了解决幻读innodb
-- 引入了间隙锁,锁住两个纪录间的空隙比如id=1,id=4之间有个间隙可能插入2,3,4的数据,而for update的时候会加行锁,还有间隙锁,同
-- 时间隙锁的冲突就是插入的动作,而间隙锁之间不存在冲突关系

-- 间隙锁和行锁合称: next-key lock,每个next-key lock前开后闭(每一个索引都有一个不存在的最大值作为闭区间),而间隙锁是开区间.
-- eg: t3: id,a,b三个字段
insert into t3 values(0,0,0),(5,5,5), (10,10,10);
-- 上面初始化3条数据,就会产生4个间隙:(负无穷,0),(0,5),(5,10),(10,正无穷),而for update的时候除了加上三个行锁还会加上
-- 上面四个间隙锁,而三个行锁对应的id就是0,5,10,加上间隙锁的开区间结果就是(负无穷,0],(0,5],(5,10],(10,supremum]这就
-- 是next-key lock也即是前开后闭合的锁,完全锁住了整个表的记录和间隙.(supremum:innodb为索引生成的一个不存在的最大值,因为
-- 正无穷是开区间,而next-key lock的规则是后闭合)
select * from t where d=5 for update;

-- 间隙锁的引入虽然解决了幻读问题,但同时锁住了表更大的范围,影响了并发度,因为所有的插入都会阻塞掉,容易发生死锁eg:
-- a,id=9不存在,会加上间隙锁
begin; select * from t where id=9 for update;
-- b,同样会加上间隙锁,insert等待a释放
select * from t where id=9 for update;
insert into t values(9,9,9);
-- a,等待b释放间隙锁,形成死锁
insert into t values(9,9,9);

-- 间隙锁是在可重复读的隔离级别产生的,如果业务要求不需要可重复读,设置成读提交就不会有这个问题,但是读提交可能会出现数据和日志
-- 不一致问题,需要把binlog格式设置成row,这也是使用最多的组合binlog_format=row





------------------------------------- Lock Rule -------------------------------------
-- 加锁规则:两个原则,两个优化,一个bug
-- 原则1:加锁的基本单位是next-key lock,前开后合
-- 原则2:查找过程中访问到的对象才会加锁(访问到的是索引,实际上锁就是加载索引上)
-- 优化1:索引上的等值查询,给唯一索引加锁的时候,next-key lock退化为行锁
-- 优化2:索引上的等值查询,向右遍历且最后一个不满足等值条件的时候,next-key lock退化为间隙锁
-- bug:唯一索引上的范围查询会访问到不满足条件的第一个值为止

-- 验证原则1和优化2
-- a:首先加next-key lock(5,10],id=7不存在,遍历到id=10不足条件,退化成间隙锁(5,10)
begin; update t3 set d=d+1 where id=7;
-- b:blocked
insert into t3 values (8,8,8);
-- c:退化之后行锁id=10释放,这个语句不被阻塞,ok
update t3 set d=d+1 where id=10;

-- 验证原则1,2和优化2
-- a:首先加next-key lock是(0,5],c是普通索引,继续查找下一条数据c=10,这个时候加next-key lock(5,10],然后c=10不满足
-- 退化成间隙锁(5,10)
begin; select id from t3 where c=5 lock in share mode;
-- b: 这个时候b去更新id=5也即是c=5的数据,可以更新成功,因为原则2访问的对象加锁,锁是加在c索引上,而查询id直接在c索引上覆盖
-- 查出,所以不需要访问id主键索引,也就没有加锁,id=5可以更新.(注意是in share mode不是for update,innodb认为后者就是为了
-- 更新数据,就会给主键索引加上锁.同时也可以看出来,后续使用in share mode加读锁的时候,如果避免数据被更新的话,就必须绕过覆盖
-- 主键索引优化,查询索引中不存在的字段,这样就会给主键加上索引,更新block)
update t3 set d=d+1 where id=5;
-- c: 因为间隙锁(5,10),所以block
insert into t3 values(7,7,7);

-- 验证原则2锁是加在访问的对象上,也即是索引上,上面的查询id可以update,但是查询d需要访问主键,就会加X写锁
-- a:查询d没有覆盖索引,就需要访问主键索引,这个时候b去更新id=5就会被block
begin; select d from t3 where c=5 lock in share mode;
-- b;没有索引覆盖,就会访问到主键索引,访问到的对象加锁,这个时候block
update t3 set d=d+1 where id=5;

-- 验证等值查询才会优化
-- a:首先是(5,10]等值退化成id=10的行锁,然后是范围查询,大于10的第一条是15也就是(10,15],此刻的锁是id=10和next-key
-- lock(10,15],因为是范围查询所以锁不发生退化
begin;select * from t3 where id>=10 and id<11 for update;
-- b:id=8插入成功,13的插入失败
insert into t3 values(8,8,8);
insert into t3 values(13,13,13);
-- c:因为是范围查询,不是等值查询,所以索引上的锁不退化,包含15这一行锁,所以block
update t3 set d=d+1 where id=15;

-- 验证bug,唯一索引范围锁,会访问到第一个不满足条件的第一行为止
-- a:应该加上(10,15]next-key lock,并且因为是唯一索引,也就停止扫描,但是innodb实际上会多访问一个,也就是第一个不满足条件的id=20的数据,因此访问到
-- 的都要加锁,也就是(10,15],(15,20],这应该是一个bug,官方系统有提出bug,但是尚未verified.
begin;select * from t3 where id > 10 and id <= 15 for update;
-- b:由于bug,id=20会被block
update t3 set d=d+1 where id=20;
-- c:同样(15,20]),也会block
insert into t3 values(16,16,16);
select * from sys.innodb_lock_waits where locked_table = '`test`.`t3`'\G;





------------------------------------- WAL -------------------------------------
-- wal: write ahead log是在将元数据的变更操作写入到持久稳定的db之前;先预先写入到一个log中,然后再由另外的操作将log apply
--   到外部的持久db里去.这种模式相当于批量操作磁盘,将磁盘随机访问改为顺序写,性能大大提高.

-- 1.连续I/O:指的是本次I/O给出的初始扇区地址和上一次I/O的结束扇区地址是完全连续或者相隔不多的.反之,如果相差很大,则算作一次随机I/O

-- 2.1连续I/O比随机I/O效率高的原因是:在做连续I/O的时候,磁头几乎不用换道,或者换道的时间很短而对于随机I/O如果这个I/O很多的话,
--   会导致磁头不停地换道,造成效率的极大降低.

-- 2.2因为随机读写的话,每次IO操作的寻址时间和旋转延时都不能忽略不计,而这两个时间的存在也就限制了IOPS的大小,而顺序读写相当于批量
--   操作,只需要一次寻址几乎不用换道,可以忽略不计寻址时间和旋转延时,性能主要花费在数据传输的时间上.





------------------------------------- FLUSH -------------------------------------
-- mysql刷脏页flush行为
-- 脏页:内存页数据与磁盘页不一致,数据flush之后就一致了,这个时候是干净页.(当内存不够用时,脏页要flush之后才能复用,干净页可以直接释放复用.)
-- 利用WAL机制,MySQL将随机写转换为顺序写而提升性能,但是内存中的数据存在脏页,因为只更新到内存,而没有更新到磁盘,而脏页会被后台
-- 线程flush刷到磁盘,这个时候会占用资源,可能导致查询或者更新语句响应时间长一些.

-- flush的场景
-- 1.mysql空闲的时候,这个时候我们也不需要关注性能问题;
-- 2.数据库将要关闭的时候,这个时候也不需要关注性能问题;
-- 3.redo log写满了,这个时候系统就不能再接受更新,写性能0,要尽量避免InnoDB的redo log满载;
-- 4.内存不足,这个时候要释放空间,会flush脏页;
-- 因此,当一个查询要淘汰脏页过多时,就会导致查询响应时间过长,而当日志写满刷脏页时,这个时候更新全部等待,写性能为0,对于业务敏感来讲,不可接受.

--Flush刷脏页控制策略
-- 1.首先设置innodb_io_capacity告诉innodb刷脏页的能力,建议设置成磁盘的iops(fio工具测试),如果设置偏小,innnodb认为磁盘
--   性能差,刷脏页速度会控制很慢,造成脏页累积过多,redo log爆满,影响读写速度.

-- 2.innodb控制刷脏页的速度决定性因素有两个,一个是脏页的比例,一个是redo log的写入速度,它会根据这个两个值,计算对比取出较大
--  的值(百分比).然后乘io_capacity来作为刷脏页的速度.

-- 3.脏页"连坐"策略innodb_flush_neighbors=1,如果刷脏页的时候相邻的数据页也是脏页.就会连带着一起flush,多米诺骨牌效应,
-- 在机械硬盘时代,这种联动群刷效应可以减少随机io操作,但是如果是ssd这种iops较高的设备,性能瓶颈往往不是IOPS,所以只需要刷自
-- 己,减少sql的响应时间(mysql8+已经色湖之默认值为0,关闭连坐机制)
innoDB_flush_neighbors = 0

-- 4.脏页比例（不要经常接近75%）计算pages_dirty/pages_total
select VARIABLE_VALUE into @a from performance_schema.global_status where VARIABLE_NAME = 'Innodb_buffer_pool_pages_dirty';
select VARIABLE_VALUE into @b from performance_schema.global_status where VARIABLE_NAME = 'Innodb_buffer_pool_pages_total';
select @a/@b;

-- 5. redo log设置太小很快就满载,就会不停的flush(change buffer不停的被merge也相当于失效),这个时候就表现出磁盘压力小,
--  但是数据库间歇性的性能下跌





------------------------------------- SPACE -------------------------------------
-- 1.表数据既可以存在共享空间,也可以是单独的文件,有参数innodb_file_per_table控制,off表示放在系统共享表空间,跟数据字典放在
--   一起,on表示存储在单独的.ibd文件,mysql5.6+默认就是on,建议也使用on,单独的文件便于管理,而且drop表的时候,就会直接释放
--   空间,如果是off即使删除表,也不会释放空间.
innodb_file_per_table = on

-- 2.drop删除表可以释放空间,但是删除行却不会释放空间,因为innodb的数据是按照数据页的方式存储,不管是delete一条数据,还是一个
--   一个数据页,或者是一个表,只是标记为删除,可以复用,如果下次插入的数据,符合范围条件,就直接复用掉了；如果是一个数据页可
--   复用,那么如果有需要申请新的数据页时,就会直接复用这个数据页；而delete整个表,就是把所有数据页标记为可复用,磁盘上文件
--   大小并不会变小,这些可复用的空间,就相当于空白,但是仍然占有空间；同时插入/更新数据,如果造成数据页的分裂也可能造成空洞
--   所以,经过大量增删改的数据表,会存在大量的空洞,要想整理收缩这些空间,可以通过重建表来到目的.

-- 3.重建表:alter命令5.5之前时加锁的通过在server端创建当前表的临时表table,然后自动完成数据的转存,表名更换,删除旧表(t-tmp-t)
--   但是整个过程禁止数据的更新,否则数据丢失,所在这个DDL不是online的,而5.6+之后引入了Online DDL,与上面的区别是整个过
--   过程是在innodb内部完成的,同时创建临时文件file,而生成临时文件的过程中的更新操作会记录到日志row log；临时文件生成后在
--   把log更新进入,这个DDL过程可以认为是Online的.(虽然DDL之前都获取MDL锁(先是写锁,为了实现online自动退化为读锁,不释
--   放锁的原因是防止其他线程做ddl),对于一个大表来说,整个ddl过程中最耗时的就是数据copy的过程,但是这个过程有了row log是
--   可以接受增删改操作的,所以锁的时间会很短,整个过程可以认为是Online的)
alter table t engine = InnoDB
-- 3.1 有些特殊情况,重建表之后可能空间反而变大一点,一种可能是不久前已经重建过一次,因为重建表也不会把整个数据页占满,每页会留1/16
--   给后续更新使用,如果不久前重建过一次,刚好更新的数据占用了1/16分之一,这个时候再次重建表空间反而变大,还有一种可能就是本身
--   就没有空洞(也是不久前重建表),这个时候再重建表,ddl期间刚好由dml执行,可能会引发新的空洞.

-- 4.对于很大的表来说,还是会占用IO和CPU资源,如果是线上服务,建议使用github的开源工具处理:gh-ost

-- 5.inplace DDL:online DDL操作的时候是在innodb内部创建临时文件,不5.5之前那样需要在server端创建创建临时表,这种在innodb的
--  online操作就是inplace DDL操作,但是inplace DDL并不一定是online的,例如添加全文索引,这个时候仍然是加锁,阻塞写操作
--  看起来就不是online了
alter table t add fulltext(email);

-- 6.1 相当于online的重建表recreate(5.6+)
alter table t engine = InnoDB;
-- 6.2 不是重建表,只是对索引信息重新统计(MDL锁)
analyze table t;
-- 6.3  相当于recreate + analyze
optimize table t;





------------------------------------- COUNT(?) -------------------------------------
-- innodb中对count(*)取行数做了专门的优化,按照效率来讲count(*)>count(1)>count(id)>count(filed),因此建议count(*)

-- 1.count(filed):innodb首先从记录一行行读取数据,取出字段返回给server层(涉及解析数据,字段拷贝),如果字段定义为not null则
--  直接按行累加,如果定义可以为null,则还需要把值取出来判断一下,不是null再进行累加

-- 2.count(id):与count字段类似,遍历表取出id,返回给server层,主键肯定不为null,直接进行累加,但是中间仍然涉及到id字段的解析copy

-- 3.count(1):innodb遍历表,但是不取值(空白行)直接返回server,server给每一行放一个1进去,同样不可能为null,所以也是直接累加
-- 但是少了取字段,解析copy工作

-- 4.count(*):因为innodb对这个做了专门的优化,专门用来获取数据行数的,虽然是count(*)但是并不会取出任何字段,也不会是null
-- 直接按行累加,实际速度与count(1)类似,不涉及字段解析copy,性能相接近(仍然建议使用count(*)专业用法).

-- myisam中因为不支持事务,它会把一个表的总行数,直接存到磁盘上,count(*)直接返回这个数字,不需要遍历数据,所以效率高
-- innodb因为事务支持,并发能力等优于myisam,也是目前最流行的存储引擎,也正是因为事务的存在,innodb才不能像myisam一样直接记录
-- 一个总行数,因为mvcc多版本并发控制,某一时刻的行数并不是确定的,只能去遍历数据,根据事务隔离级别等只计算可见的行数,当然优化器
-- 在扫描的时候会选择最小的索引树.

-- rows字段不能用于显示表有多少行,虽然执行速度挺快,因为这个值是根据采样来计算的,也就是索引统计的那种采样方式,每个数据页统
-- 计做估算,官方文档表示误差在40%-50%,所以这个数据并不准确.
show table status;

-- innodb保存行数需求
-- 对于有频繁查询总数的业务要求时,每次都count(*)太耗费性能,只能自己基数,使用redis基数有误差风险,因为redis和innodb是两个
-- 不同的存储系统,不支持分布式事务,无法拿到一致性视图,因此会有redis计数和实际查询的数据不一致;建议方案是利用mysql的一致性视
-- 图解决,本质上使用count(*)计数的原因就是因为事务的存在导致行数不确定,所以需要时时查询可见行数,同样可以利用事务的可见性来完
-- 成计数问题,保证其他线程看到的行数,与实际查询的数据一致.(同时记录行数的的逻辑,应该先插入数据,再更新行数,因为更新行数,会竞争
-- 并发写锁,插入不涉及,因此把竞争的锁的时间放到后面操作,整体提高执行效率)





------------------------------------- ORDER BY -------------------------------------
-- mysql的字段排序,有全字段排序和rowid排序两种算法,以及利用索引排序,mysql会分配一块内存sort_buffer做排序
-- table(4000行): `id` `city` `name` `age` `addr` PRIMARY KEY (`id`), KEY `city` (`city`)
select city,name,age from t where city='杭州' order by name limit 1000;

-- 1.全字段排序: 上述语句会初始化sort_buffer,放入city,name,age三个字段,然后查找city树一行行获取所有满足杭州的id,然后
-- 回表获取行取出三个字段值存入sort_buffer,然后sort_buffer中安装name排序,取出1000行,这个时候sort_buffer中对所需字段
-- 字段进行排序.这个时候如果查询的数据量过大,那么sort的内存不够用,就会利用磁盘临时文件来辅助排序,而磁盘操作显然性能差,可以通
-- 过如下optimizer_trace查看临时文件的使用情况:

-- 1.1 number_of_tmp_files = 12,可以看到使用了12个临时文件,因为sort内存放不下,所以使用了外部排序,外部排序一般是归并
--  排序算法,mysql将排序的数据分成12份分别排序,然后再合成一个有序的大文件.如果sort内存sort_buffer_size超过排序的数据量
--  大小,那么这个tmp_files就等于0,是直接在内存中完成排序的.

-- 1.1.1 还有一种可能导致tmp_files =0,就是排序算法没有使用归并排序,即使sort内存放不下(4000),但是查找的数据总数没有超过
-- sort_buffer那么就会采用优先队列算法,再内存中比较替换选择符合的数据,比如limit 100最终结果只需要100行,就会一次性读取100
-- 行到sort中,然后依次比较剩下的3900行,最终按顺序取出对比后的100行,中间没有涉及临时文件,这个时候tract结果显示tmp_files为0
-- 但是fileSort_priority_queue_optimization: chosen = true,表示采用了优先队列算法
select city, name,age from t where city='杭州' order by name limit 100;

-- 1.2 sor_mode:代表排序的情况,sort_key代表name,packed_additional_fields代表压缩算法,对字符串的排序即使字段定义
-- varchar(16),也是根据实际长度进行排序.

-- 1.3 examined_row=4000,代表实际排序行数,也即是满足查询条件的记录有4000条(总扫描主键树次数4000)

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

-- 2.rowid排序:当mysql认为单行数据的长度太大,也就是上述的全字段长度(city, name,age)超过max_length_for_sort_data
-- 的长度,就认为排序的长度太大,sort内存里存放的行数太少,mysql会切换成rowid算法排序,这个时候只在sort内存中放入name,id两
-- 个字段,一个是排序字段一个是主键id,然后与上述的全字段排序类似,查询之后排序,只不过这个时候没有age字段,还需要从排序完成之后
-- 取出的1000个id,依次去主键行回表取出1000条数据的age字段.

-- 2.1 number_of_tmp_files = 10,因为每一行数据变少,所以临时文件也少了,提高性能

-- 2.2 sor_mode:代表排序的情况,sort_key代表name,rowid代表参与排序的字段只有name和id

-- 2.3 examined_row=4000,代表实际排序行数,也即是满足查询条件的记录有4000条(但是总的扫描行数是5000,因为多了一次回表操作)

-- max_length_for_sort_data,sort_buffer_size
show variables like 'max_length_for_sort_data';
show variables like 'sort_buffer_size';
-- 设置当前连接的大小
set max_length_for_sort_data = 2048;
set sort_buffer_size = 2097152;
-- 设置全局大小
set global max_length_for_sort_data = 2048;
set global sort_buffer_size = 2097152;

-- 3.利用索引排序,explain结果extra中没有了fileSort,利用复合索引本身就是排序的,所以直接取出1000行回表即可,总扫描1000
alter table t add index city_user(city, name);

-- 4.利用覆盖索引,排序并且覆盖age,explain查看extra没有fileSort而且多了using index
alter table t add index city_user_age(city, name, age);


-- 5.获取表中的随机行order by rand()使用explain查看using temporary,using filesort,效率低下不建议使用.
explain select word from words order by rand() limit 3;
-- 5.1 当涉及到临时表的时候,一般是内存临时表,使用的是memory引擎,但是当临时表的大小超过tmp_table_size就会转换磁盘临时表
show variables like 'tmp_table_size';
-- 5.2 涉及内存表的排序,mysql就不会选择全字段排序,因为全字段排序的目的就是减少回表操作,减少磁盘的访问,但是内存表都是内存操作
-- 所以涉及排序优先选择rowid排序,然后会内存中回表.





----------------------------------- PERFORMANCE -------------------------------------
-- 查一行数据慢的原因:表锁,行锁,一致性读问题造成
-- 1.遇到mdl锁,查询阻塞问题:A加了mdl锁,B去查询,就会等待A
-- a加锁
lock table t write;
-- b查询,堵塞
select * from t where id = 1;
-- 查看原因:Waiting for table metadata lock
-- 有一个线程是sleep,理论上就是那个锁线程,但是信息不够准确,可以通过下述的blocking_pid命令确定确切的阻塞pid
show processlist;
-- 通过sys.performance_schema,查看具体锁进程id信息,performance_schema=on(10%左右性能损失),然后kill锁进程即可
select blocking_pid from schema_table_lock_waits;
kill 32;
-- performance_schema=on而且ENABLED='YES',TIMED='YES',才可以查看到上述的blocking_pid
show variables like 'performance_schema';
select * from performance_schema.setup_instruments where name='wait/lock/metadata/sql/mdl';
update performance_schema.setup_instruments set ENABLED='YES',TIMED='YES' where name='wait/lock/metadata/sql/mdl';

-- 2.等flush,mysql对表flush的时候会暂时关闭锁,但是一般速度很快,但是当flush的过程被阻塞的时候,flush就会进而阻塞其他线程查询
-- flush命令可以控制所有或者指定的表,执行的时候会添加read lock.
flush tables;
flush tables t;
-- 当一个线程sleep时,一个线程flush的时候阻塞,这个时候如果还有一个线程查询就会被阻塞直到flush结束.
select sleep(1000);
flush tables t;
select * from t where id =1;
-- 通过show processlist查看flush情况,根据id进行kill掉阻塞flush的进程,或者kill掉flush的进程??
show processlist;
kill id;


-- 3.行锁等待,一个线程开启写锁,这个时候读取的时候加读锁,就会被写锁阻塞
begin; update t set c = c + 1 where id = 1;
-- 读取阻塞直到上一个commit
select * from t where id = 1 lock in share mode;
-- processlist看出阻塞,然后利用innodb_lock_waits查出pid杀死
show processlist;
select * from sys.innodb_lock_waits where locked_table = '`test`.`t`'\G;
-- kill id,不是kill query是停止当前执行的语句,但是update语句已经执行完,kill query无法释放锁
kill id;


-- 4.还有一种查询慢的情况,就是开启一致性读的时候,另一个线程更新数据多次,这个时候一致性读就要利用undo log一次次计算到更新前的值
-- a:
start TRANSACTION  WITH consitent snapshot;
-- b:更新100w次
update t set c=c+1 where id = 1;
-- a:查询
-- 因为是一致性读,需要把上面的100w次更新利用undo log依次回滚计算出未更新的值,所以查询慢
select * from t where id = 1;
-- 因为是当前读,直接读出最后的更新值.
select * from t where id = 1 lock in share mode;






----------------------------------- TEMPORARY IMPROVE PERFORMANCE -------------------------------------
-- 1 当连接数不够用时,异常too many connections,可以手动kill服务端的连接,相当于服务端wait_timeout超时自动断开连接一样
-- a:占用连接,但是有事务存在,不能kill
begin; insert into t3 value(9,9,9);
-- b:事务已经提交,事务之外占有连接,这种连接相对而言比有事务的安全一点(这也是一种有损方案,临时提高性能)
select * from t3 where id =1;
-- 查看到两个线程都在sleep,不能确定具体事务状态,通过innodb_trx表确定
show processlist;
-- 查看事务内的连接id参数: trx_mysql_thread_id
select * from information_schema.innodb_trx\G;

-- 1.1 减少连接过程的消耗,通过修改权限参数,使mysql在建立连接过程中,跳过权限验证,不建议使用,危险高
-skip-grant-tables



-- 2 导致慢查询问题,通常三种可能:索引没建好,sql语句没写好,mysql选错索引
-- 2.1 索引没建好的话,mysql5.6+已经支持online ddl,可以直接alter table添加索引.如果是主备库通常是备库关闭binlog,然后alter,然后主备切换,再
-- 次alter,这也是紧急处理方案,更为安全的做法是使用github开源的gh-host
set sql_log_bin=off

-- 2.2 sql语句没写好,(mysql5.7+)线上紧急处理的时候使用query_rewrite(安装插件)功能,利用存储过程对于特定的语句实行替换,达到改写sql的目的eg:
-- 这种会导致innodb全表扫描
select * from t1 where id +1 = 10000;
-- 这种利用主键索引,只需要扫描一行
select * from t1 where id  = 9999;
-- 利用query_rewrite替换,然后调用call存储过程
insert into query_rewrite.rewrite_rules(pattern,replacement,pattern_database)
values("select * from t1 where id + 1 = ?", "select * from t where id = ?-1","test");
call query_rewrite.flush_rewrite_rules();
-- show查看rewrite插件生效
select * from t1 where id +1 = 10000;
show warnings;
-- 慢查询日志也可以看到实际执行
select * from t1 where id = 10000-1;

-- 2.3 mysql选错了索引导致性能问题,同样是利用rewrite插件重写sql,强制force index选择索引eg:
select * from t force index(a) where ..

-- 2.4 通常都是前两种,也就是索引没设计好,或者sql没写好导致的慢查询,通常避免这类错误的方法:
-- 2.4.1 上线前,开启慢查询日志slow log设置long_query_time=0保证记录每一条sql语句,观察rows_examined行数是否符合预期,同时做好模拟线上数据的测
-- 试,维护项目通常新增的sql不多,可以手动执行观察,如果是新项目,建议使用开源工具pt-query-digest检查所有的sql返回结果








----------------------------------- BINLOG -------------------------------------
-- binlog-format: statement, row, mixed
-- 不同索引的结果不同
select * from t2 /*comment*/  where a>=4 and t_modified<='2018-11-10' limit 1;
select * from t2 /*comment*/ force index(t_modified)  where a>=4 and t_modified<='2018-11-10' limit 1;

-- statement完整记录语句,容易出现主备不一致,row能精确记录语句对应的行操作,但是记录内容多,占空间较大,mixed是两者的混合,mysql会择优选取,当出现类似
-- 上面主备两个库可能选的索引不一致,导致删除的数据不一致时,mysql认为unsafe就会选取row来存储这个binlog.(而实际上越来越多的场景都会选row,做数据恢复
-- 比较方便,同时mixed还是存在一定风险,比如now()函数,见example)

-- binlog解析查看: data目录中查看生成的日志:server1-bin.000001
-- 1.format为statement时,直接查看
show binlog events in 'server1-bin.000001';

-- 2.当为row的时候,还需要解析binlog中的event,根据pos
show binlog events in 'server1-bin.000001';
bin/mysqlbinlog -vv data/server1-bin.000001 --start-position=1805;

-- delete语句当为statement时,binlog记录完整的语句,但是mysql会警告,因为主从同步时,选不同的索引会导致删除不同的语句,为row则是记录删除的数据内容
delete from t2 /*comment*/  where a>=4 and t_modified<='2018-11-10' limit 1;
show warnings;





