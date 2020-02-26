# redis除了5种常用的基础数据结构外,还有一些高阶数据结构,有一些特定的使用场景,比如:bit(位图),hyperLogLog,bloom等

################################################### Bit ###################################################
# 很方便存储bool类型数据,当数据量大的时候节省空间,常用于记录用户一年的签到情况0,1表示,不需要使用开销较大的k-v结构
# 存储字符的时候,需要获取字符的ASCII码对应的二进制值

# set/get
setbit k 0 1
setbit k 1 1
setbit k 2 0
getbit k 0

# bitcount/pos [start end]统计和计算位置,后面是字符的范围,要是2的次方
set k v
# v的二进制一共多少个1(统计一共签到多少次)
bitcount k
# 0-0第一个字符,0-1前两个字符
bitcount k 0 0
bitcount k 0 1
# 第一个0位,1位(统计哪一天开始签到)
bitpos k 0
bitpos k 1
# 第一个字符的1位,第三个字符的0位
bitpos k 1 0 0
bitpos k 0 2 2

# 高阶bitfield操作?





################################################### HyperLogLog ###################################################
# hyperLog通常用于统计,通常情况下统计计数可以使用incrby当作计数器,但是如果需要统计去重的数量,就需要用set集合存储,比如统计页面不同的id访问数量,可以
# 使用set集合,sadd添加id,然后scard获取集合大小得出不同id数量,但是如果页面的访问量级大,就需要很大的set集合占用空间,这个时候可以考虑使用hyper结构,占
# 有空间12k,但是hyper的去重不精确,误差大概0.81%,所以适用于这种量级大,但是对结果误差不是高的统计场景.

# add/count,注意基于heyper的算法,key不能是一个字母.(pf是发明这个数据结构作者的名字缩写)
pfadd key v
pfadd key v2
pfadd key v2 v2 v2 v3 v4 v5
# 2-自动去重
pfcount key

# merge不同的key
pfadd source-key v
pfadd source-key v1
pfadd source-key v2
pfadd dest-key v1
pfadd dest-key v3
pfmerge dest-key source-key
# 3,4
pfcount source-key
pfcount dest-key





################################################### Rebloom ###################################################
# redis需要安装Rebloom插件,布隆过滤器Bloom Filter是专门用于去重,同时节省空间,但是判断存在误差,相当于一个不精确的set,它能正确判断一个元素一定不
# 存在,但是有可能不存在的它会判断存在,误判率默认是1%,具体可以通过调整error_rate(0.01)和initial_size(100),错误率越低,就需要越大的空间.比如新闻
# 广告推送给用户,但是只能推送没有浏览过的id,如果数据量大无论是关系型数据库,还是使用缓存,日积月累下都不是可行方案,这个时候可以使用bloom节省,快速判断id
# 一定不存在就可以推送给用户,偶尔会误判,一个id用户没浏览,也不会推送,这个损失误差能接受.(设置错误率,然后最好精确估计初始值,再加上一定的冗余空间)

# 布隆原理:大致结构维护了一个超大的位数组,还有几个(假设3个)无偏hash函数(无偏就是把hash值计算的很均匀,减少冲突),然后add值的时候,会通过这3个无偏hash
# 函数分别计算出3个hash值然后取模等等,最终分别得到3个数组下标插入1,当下一个值来的时候,仍然计算hash得出对应的三个数组下标,如果有一个为0就一定不存在,但
# 是如果都为1也有一定可能不存在,因为即使使用了无偏hash还是有一定几率计算出不同的key得到相同的下标,这也是误差的原因,所以设置好空间初始容量很重要,不要让
# 实际元素大于初始容量,如果大于就需要重建bloom过滤器,把所有的历史数据转移,同时error_rate也不会因为超过容量就错误率暴增.此外bloom空间的节约体现在存
# 储结构上,正常的set集合需要存储数据的内容,以及指针等内容,而bloom只需要存储元素的指纹信息??所以节约空间.

# add/exists
bf.add k v
# 0不存在,1存在
bf.exists k v


# 批量
bf.madd k v1 v2 v3 v4
# 1 1 0
bf.exists k v1 v2 v8





################################################### GeoHash ###################################################
# redis3.2+增加了地理位置geo模块,可以实现经纬度的计算,如:定位附近的人,附近的餐馆等功能
# 关系型:
# 假如使用关系型数据库维护一个坐标(id,x,y)三个属性定位一个人的位置,如果要查找这个id附近的元素,就需要遍历整个表然后计算出所有的距离排序,最后筛选;
# 这种计算量过大,性能不满足,可以通过优化限定查找矩形区域,比如查找id附近半径r的数据,再加上复合索引(x,y),能满足并发不是很高的场景,如果用户在r范围
# 没查找到目标,可以继续加大r的值做筛选 sql:
select id from t where x0-r < x < x0+r and y0-r < y < y0+r

# Geo:
# 而对于高并发性能要求较高的业务,业界提供了地理位置GeoHash算法,大致上是将一个二维的坐标通过geo算法映射到一维的整数,当需要计算距离时,只需要在这个一
# 维的线上取点即可,geo算法会把地球看成二维平面,利用算法划分切割最终编码得出数字,然后再对这个整数数字做base32编码变成字符串;redis使用52位的整数编码
# 然后使用geo的base32得到字符串,本质上时zset数据结构,52位的编码数字放到score(浮点类型,无损储存整数),value是元素的key,这样查询时只需要通过score
# 排序就可获取到附近的位置

# add: 添加元素到指定集合,明确经纬度以及key
geoadd company 116.48105 39.996794 juejin
geoadd company 116.514203 39.905409 ireader
geoadd company 116.489033 40.007669 meituan
geoadd company 116.562108 39.787602 jd 116.334255 40.027400 xiaomi

# dist: 获取两个元素之间的距离,单位支持多种
geodist company juejin ireader m
geodist company juejin ireader km
geodist company juejin meituan mi
geodist company juejin jd km
geodist company juejin xiaomi km
geodist company juejin juejin km

# pos: 获取元素的经纬度位置,因为存储需要映射以及反向映射,存在一些误差,造成精度上一些损失可以接受
geopos company juejin
geopos company ireader
geopos company juejin ireader

# hash:获取对应经纬度的hash值(可以通过网站填写路径参数,获取hash值对应的经纬度:http://geohash.org/{hash})
geohash company ireader
geohash company juejin

# radiusbymember: 查看附近的公司(包含自己),可选参数withcoord(坐标) withdist(距离) withhash(一维整数值)
georadiusbymember company ireader 20 km count 5 asc
georadiusbymember company ireader 20 km count 3 desc
georadiusbymember company ireader 20 km withcoord count 3 asc
georadiusbymember company ireader 20 km withdist  count 3 asc
georadiusbymember company ireader 20 km withhash  count 3 asc
georadiusbymember company ireader 20 km withcoord withdist withhash  count 3 asc

# radius: 根据经纬度查询集合内的元素
georadius company 116.514202 39.905409 20 km withdist count 3 asc

# rem: 本质上时zset结构,可以使用rem删除元素,range遍历元素
zrem company juejin
zrange company 0 -1

# redis中单个key对应的数据量不宜超过1M,因为集群环境中需要节点的数据迁移,如果key的数据过大,就会照常集群迁移出现卡顿,影响线上服务;而地图应用中,往往
# 数据量过大,所以建议使用单独的redis实例部署,不适用集群环境





################################################### Lock ###################################################
# 分布式锁:比如一个操作需要修改用户的状态,先读后改然后存,如果并发出现,在没有保证原子性的情况下,可能会出现读的是旧值
# 原子操作: 不会被线程调度机制打断的操作,这种操作一旦开始,就一直运行到结束,中间不会有任何context switch线程切换

# setnx: redis一个使用场景就是分布式锁,本质上就是通过setnx命令占据锁来控制并发,直到释放锁之后,别的线程才能拥有该对象,如下,设置lock为true,直到
# 业务逻辑处理完,删除这个lock,如果未删除lock,即使下一个线程setnx因为已经存在也不会拥有锁,但是如果删除lock之前出现异常,就会出现死锁没法释放
setnx lock true
del lock

# expire: 给锁加一个过期时间,这样异常发生在del之前expire之后仍然到过期时间,自动释放,但是如果发生在设置过期时间之前,仍然会得到死锁
setnx lock true
expire lock 5
del lock

# ex-nx: 由于上面的expire命令和setnx命令不是原子操作,所以可能导致死锁,而这两个命令之间又存在依赖关系,expire执行之前必须是setnx执行成功之后,
# 如果不成功,也不能执行expire,相当于存在了if-else分支因此也无法使用redis事务解决,前期redis社区开源了不同的分布式锁library解决这个问题,但是复
# 杂难用,在redis2.8+之后作者对set指令做了扩展,保证setnx和expire一起执行,解决了这个问题
set lock true ex 5 nx
del lock

# 锁冲突: 如果第二线程加锁失败的时候,客户端通常的处理逻辑有三种
# - 直接抛出异常,响应用户稍后重试: 适用于用户发起的操作,弹窗提示用户,让用户自己手动重试,也相当于人工延迟(也可以前端收到重试响应,自己延迟重试)
# - 直接sleep,稍后自行重试: 不建议sleep,会阻塞当前线程的消息处理全部延迟,如果消息过多可能出现死锁等问题
# - 将请求转移到延迟队列,等待重试: 适用于异步处理,避开了当前冲突

# 超时: 虽然解决了一致性问题,但是超时问题仍然存在,所以锁的过期时间一定要大于业务逻辑执行的时间,假如提前释放了锁,那么业务逻辑未执行完,只能等待下次
# 获取锁继续执行,但是业务逻辑上就不是严格的串行了,所以可能需要人工介入处理解决






################################################### Mq ###################################################
# 延时队列:通常消息队列可以使用rabbit等专业的mq,但是配置使用稍微有点复杂,如果是简单的一组消费者消息队列,就可以使用redis来简单实现

# 异步消息队列: 通过redis的list列表数据结构,配合rpush-lpop或者lpush-rpop命令实现生产消息入对,消费消息出队,也即是先入先出
rpush queue msg1 msg2 msg3
lpop queue
lpush queue msg1 msg2 msg3
rpop queue

# 队列延迟: 通过轮询pop可以消费队列,但是如果队列为空的时候,就会空轮询,造成不必要的额外开销,可以利用blocking实现延迟阻塞队列,blpop/brpop在队列
# 没有数据的时候会阻塞休眠,直到队列中产生消息,会立即苏醒消费消息;但是如果长时间阻塞,redis会认为是空闲连接,主动断开这个链接,这个时候blocking-pop
# 就会表现出异常抛出,所以消费端的业务逻辑要注意捕获异常,重试消费等
rpush queue msg1 msg2 msg3
blpop queue
lpush queue msg1 msg2 msg3
brpop queue

# 延时队列: 可以通过redis的zset数据结构,配置score属性zrem操作实现队列的延时消费(不是上述的延迟阻塞队列,那种是立即消费消息,这里是到时间才消费),
# 首先是通过zadd入队,入对的同时设置score为延时消费的时间,然后客户端loop轮询通过zrangebyscore获取第一个满足条件的消息消费;同时需要提供多个线程
# 保证可用性保证消息一定消费掉,但是多个线程就涉及到并发问题,所以需要通过zrem命令的返回值保证是否竞争到了任务
# eg:
# 1.设置score为当前时间+延迟5s
# 2.通过byscore获取小于当前时间的msg,只获取第一条,也即是应该消费的消息
# 3.多线程loop中真正消费消息的线程必须是zerm返回1,也即是竞争到消息的线程
# 4.但是存在空轮询的问题(可能优化保证bscore和zem原子操作,去掉空轮询问题)
zadd queue current + 5 msg
zrangebyscore queue 0 current 0 1
zrem queue msg





################################################### Limiter ###################################################
# 限流: 当系统处理能力有限时,需要限制一定的请求量对系统施压;同时还有如果需要对用户行为做限制,如一分钟内不能请求5次验证码,也是需要限流
# 简单限流:
# 以上述的一分钟内限制操作数(ction)为例,redis中的zset可以利用score来控制这个period"一分钟",本质上这是要给滑动窗口,随着时间推移,我们需要删除滑动
# 窗之外的数据,值计算这个窗口内的操作次数,同时每次操作为数据设置一个period多一点的过期时间,代表如果一个period滑动窗时间外,这条数据已经失去统计意义,
# 及时删除节省空间:每一个用户的action用户一个zset维护,操作的时候的时间作为score,value值不重要只需要保证唯一,也用时间戳保存(uuid占内存),然后每一次
# action的时候触发清空旧数据,计算period滑动窗内的数量,判断是否大于5次即可(同一个key操作可以使用jedis等的pipeline操作提升存取效率)
zadd uidaction current current
zremrangebyscore uidaction 0 current-period
zcard uidaction
expire uidaction period+1

# 漏斗限流
# redis-cell: redis4.0提供了这个限流模块,支持原子操作的限流指令,这个模块只有一个命令cl.throttle,参数key,15表示漏斗的初始容量,30和60计算漏水
# 速率,表示每60s最多漏水30次,最后一个是可选参数,默认是1,代表每次漏的单位;这个命令返回值是五个int类型;
cl.throttle k 15 30 60 1
# 1. 0/1: 0表示允许,1表示拒绝
# 2. 15: 漏斗初始容量
# 3. 13: 漏斗剩余空间
# 4. -1: 如果拒绝添加,需要多久重试(假如是5就代表5s之后,漏斗有新的空间,可以新增)
# 5. 2: 需要多久(这里是2s之后就会清空),漏斗会清空





################################################### Scan ###################################################
# redis日常维护中需要找出包含特定前缀的key,有个简单粗暴但是基本上禁止使用的指令keys,可以根据正则获取对应规则的key,但是两个缺陷:
# 1.没有limit等范围限制,一次性输出所有满足的key,数据量大的情况下查找困难
# 2.redis单线程顺序执行指令,,keys遍历算法复杂度O(n),当千万级别的数据量就会导致redis服务卡顿,同时其他所有的读写指令都会阻塞甚至超时报错
mset user1good a user2good b user3good c usergood1 a usergood2 b usergood3 c
keys *
keys user*good
keys usergood*

# redis2.8+提供了scan命令,复杂读仍然是O(n),但是通过游标cursor分步进行不会阻塞进行,同时提供了匹配功能以及limit参数限制最大条数,这只是扫描字典
# 槽数量的hint并不是真正意义上的返回结果数量,如果hint为100那么每次游标就移动100,但是返回结果取决于这100个字典槽中有多少满足的key,可能恰好100,
# 也可能0;所以即使单次执行结果为空,也不一定遍历结束,要看返回的游标值是否为零,此外返回的结果可能有重复,需要客户端手动去重,如果遍历过程中有数据修改,
# 不一定能遍历到;服务器并不会保存游标的状态,所以需要使用每次遍历返回的游标整数值继续遍历

# scan:第一个参数是cursor(第一次执行为0,后续使用每次执行返回的第一个cursor值); 第二个是key的正则表达; 第三个是limit hint
# 返回当前corsor值,以及结果集,可能为空,如果cursor不为空就继续遍历直到为0
scan 0 match user*good count 3

# 字典结构: redis内部存储维护了一个超大的字典,相当于java中的hashmap,也就是数组+链表,而前面说的limit实际上就是要扫描的数组个数,cursor就是数组
# 的下标,假如每次扫描limit的值是10个,也就是下标移动十次,但是如果这十个下标都是空的,那么就会返回空的结果集;但是这十个数组元素,每一个又维护着一个链
# 表结构,如果恰好每一个都有值同时链表大于1那么就会遍历所有的链表,过滤匹配返回的结果集有可能会大于10个,这就是为什么结果集不确定的原因;

# 遍历顺序: 每次scan返回的cursor值,实际上就是数组的下标,redis遍历顺序采取了高位进位加法算法,而不是普通的加法算法,是考虑到字典结构的扩容/缩容导致
# 遍历的slot重复或者遗漏;高位进位加法是从高位加1进位,但是最终也会遍历所有的slot,同时缩容扩容rehash算法导致数组元素的移动不会影响高位算法,具体算法
# 后续记录学习,同时java的rehash过程是一次性替换迁移数组元素,而redis为了避免一次性迁移大量数据导致服务卡顿,采用了渐进式rehash,分批次迁移数据,这
# 就要同时保存新旧两个字典结构,查询数据时就需要扫描两个字典,将结果集合并返回
# 普通加法:0,1,2,3,4 ... 8,9
0000 -> 0001 -> 0010 -> 0011 -> 0100 -> *** -> 1110 ->1111
# 高位进位加法:0,8,4,12,2 ... 7,15
0000 -> 1000 -> 0100 -> 1100 -> 0010 -> *** -> 0111 ->1111

# scan扩展,除了遍历所有的key之外,还可以通过zscan,hsacn,sscan遍历zset,hash,set等底层的是hash的数据结构
zscan k 0 match * count 3
hscan k 0 match * count 3
sscan k 0 match * count 3

# redis中的数据结构,每一个key最好不要超过1M,因为过大的key会占用过大的内存,无论是集群中的数据迁移,还是key的删除,或者hash结构的扩容,都会临时占用
# 或者较大的内存导致redis服务出现卡顿,如果需要排查大key,就需要用scan查找所有的key获取对应的类型,得到每种类型size排名靠前的key;官方对于这一系列
# 的操作提供了扫描功能的指令
# bigkeys:扫描得到summary,描述了redis中各种类型最大key的信息,[-i 0.1是可选参数],表示每scan100条就会休眠0.1s为了防止影响redis服务.
redis-cli -h localhost -p 6379 --bigkeys -i 0.1
