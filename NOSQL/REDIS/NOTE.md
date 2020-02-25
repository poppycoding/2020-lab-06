##### 分布式锁
比如一个操作需要修改用户的状态,先读后改然后存,如果并发出现,在没有保证原子性的情况下,可能会出现读的是旧值

原子操作: 不会被线程调度机制打断的操作,这种操作一旦开始,就一直运行到结束,中间不会有任何context switch线程切换

setnx: redis一个使用场景就是分布式锁,本质上就是通过setnx命令占据锁来控制并发,直到释放锁之后,别的线程才能拥有该对象,如下,设置lock为true,直到
业务逻辑处理完,删除这个lock,如果未删除lock,即使下一个线程setnx因为已经存在也不会拥有锁,但是如果删除lock之前出现异常,就会出现死锁没法释放
```shell script
setnx lock true
del lock
```

expire: 给锁加一个过期时间,这样异常发生在del之前expire之后仍然到过期时间,自动释放,但是如果发生在设置过期时间之前,仍然会得到死锁
```shell script
setnx lock true
expire lock 5
del lock
```

ex-nx: 由于上面的expire命令和setnx命令不是原子操作,所以可能导致死锁,而这两个命令之间又存在依赖关系,expire执行之前必须是setnx执行成功之后,
如果不成功,也不能执行expire,相当于存在了if-else分支因此也无法使用redis事务解决,前期redis社区开源了不同的分布式锁library解决这个问题,但是复杂
难用,在redis2.8+之后作者对set指令做了扩展,保证setnx和expire一起执行,解决了这个问题
```shell script
set lock true ex 5 nx
del lock
```

锁冲突: 如果第二线程加锁失败的时候,客户端通常的处理逻辑有三种
 - 直接抛出异常,响应用户稍后重试: 适用于用户发起的操作,弹窗提示用户,让用户自己手动重试,也相当于人工延迟(也可以前端收到重试响应,自己延迟重试)
 - 直接sleep,稍后自行重试: 不建议sleep,会阻塞当前线程的消息处理全部延迟,如果消息过多可能出现死锁等问题
 - 将请求转移到延迟队列,等待重试: 适用于异步处理,避开了当前冲突

超时: 虽然解决了一致性问题,但是超时问题仍然存在,所以锁的过期时间一定要大于业务逻辑执行的时间,假如提前释放了锁,那么业务逻辑未执行完,只能等待下次获取锁
继续执行,但是业务逻辑上就不是严格的串行了,所以可能需要人工介入处理解决

##### 延时队列
通常消息队列可以使用rabbit等专业的mq,但是配置使用稍微有点复杂,如果是简单的一组消费者消息队列,就可以使用redis来简单实现

异步消息队列: 通过redis的list列表数据结构,配合rpush-lpop或者lpush-rpop命令实现生产消息入对,消费消息出队,也即是先入先出
```shell script
rpush queue msg1 msg2 msg3
lpop queue
lpush queue msg1 msg2 msg3
rpop queue
```

队列延迟: 通过轮询pop可以消费队列,但是如果队列为空的时候,就会空轮询,造成不必要的额外开销,可以利用blocking实现延迟阻塞队列,blpop/brpop在队列没有
数据的时候会阻塞休眠,直到队列中产生消息,会立即苏醒消费消息;但是如果长时间阻塞,redis会认为是空闲连接,主动断开这个链接,这个时候blocking-pop就会表现
出异常抛出,所以消费端的业务逻辑要注意捕获异常,重试消费等
```shell script
rpush queue msg1 msg2 msg3
blpop queue
lpush queue msg1 msg2 msg3
brpop queue
```

延时队列: 可以通过redis的zset数据结构,配置score属性zrem操作实现队列的延时消费(不是上述的延迟阻塞队列,那种是立即消费消息,这里是到时间才消费),首先
是通过zadd入队,入对的同时设置score为延时消费的时间,然后客户端loop轮询通过zrangebyscore获取第一个满足条件的消息消费;同时需要提供多个线程保证可用性
保证消息一定消费掉,但是多个线程就涉及到并发问题,所以需要通过zrem命令的返回值保证是否竞争到了任务
eg: 
1.设置score为当前时间+延迟5s 
2.通过byscore获取小于当前时间的msg,只获取第一条,也即是应该消费的消息
3.多线程loop中真正消费消息的线程必须是zerm返回1,也即是竞争到消息的线程
4.但是存在空轮询的问题(可能优化保证bscore和zem原子操作,去掉空轮询问题)
```shell script
zadd queue current + 5 msg
zrangebyscore queue 0 current 0 1
zrem queue msg
```

##### 限流
当系统处理能力有限时,需要限制一定的请求量对系统施压;同时还有如果需要对用户行为做限制,如一分钟内不能请求5次验证码,也是需要限流
 - 简单限流:
  以上述的一分钟内限制操作数(action)为例,redis中的zset可以利用score来控制这个period"一分钟",本质上这是要给滑动窗口,随着时间推移,我们需要删除滑动
  窗之外的数据,值计算这个窗口内的操作次数,同时每次操作为数据设置一个period多一点的过期时间,代表如果一个period滑动窗时间外,这条数据已经失去统计意义,
  及时删除节省空间:每一个用户的action用户一个zset维护,操作的时候的时间作为score,value值不重要只需要保证唯一,也用时间戳保存(uuid占内存),然后每一次
  action的时候触发清空旧数据,计算period滑动窗内的数量,判断是否大于5次即可(同一个key操作可以使用jedis等的pipeline操作提升存取效率)

 ```shell script
 zadd uidaction current current
 zremrangebyscore uidaction 0 current-period
 zcard uidaction
 expire uidaction period+1
 ``` 

 - 漏斗限流
redis-cell: redis4.0提供了这个限流模块,支持原子操作的限流指令,这个模块只有一个命令cl.throttle,参数key,15表示漏斗的初始容量,30和60计算漏水
速率,表示每60s最多漏水30次,最后一个是可选参数,默认是1,代表每次漏的单位;这个命令返回值是五个int类型;
```shell script
cl.throttle k 15 30 60 1
``` 
   1. 0/1: 0表示允许,1表示拒绝
   2. 15: 漏斗初始容量
   3. 13: 漏斗剩余空间
   4. -1: 如果拒绝添加,需要多久重试(假如是5就代表5s之后,漏斗有新的空间,可以新增) 
   5. 2: 需要多久(这里是2s之后就会清空),漏斗会清空
 
##### GeoHash
redis3.2+增加了地理位置geo模块,可以实现经纬度的计算,如:定位附近的人,附近的餐馆等功能
 - 关系型:
 假如使用关系型数据库维护一个坐标(id,x,y)三个属性定位一个人的位置,如果要查找这个id附近的元素,就需要遍历整个表然后计算出所有的距离排序,最后筛选;
 这种计算量过大,性能不满足,可以通过优化限定查找矩形区域,比如查找id附近半径r的数据,再加上复合索引(x,y),能满足并发不是很高的场景,如果用户在r范围
 没查找到目标,可以继续加大r的值做筛选
 ```sql
select id from t where x0-r < x < x0+r and y0-r < y < y0+r
```
   
 - Geo:
 而对于高并发性能要求较高的业务,业界提供了地理位置GeoHash算法,大致上是将一个二维的坐标通过geo算法映射到一维的整数,当需要计算距离时,只需要在这个一
 维的线上取点即可,geo算法会把地球看成二维平面,利用算法划分切割最终编码得出数字,然后再对这个整数数字做base32编码变成字符串;redis使用52位的整数编码
 然后使用geo的base32得到字符串,本质上时zset数据结构,52位的编码数字放到score(浮点类型,无损储存整数),value是元素的key,这样查询时只需要通过score
 排序就可获取到附近的位置
 
  1.add: 添加元素到指定集合,明确经纬度以及key
```shell script
geoadd company 116.48105 39.996794 juejin
geoadd company 116.514203 39.905409 ireader
geoadd company 116.489033 40.007669 meituan
geoadd company 116.562108 39.787602 jd 116.334255 40.027400 xiaomi
```
  2.dist: 获取两个元素之间的距离,单位支持多种
```shell script
geodist company juejin ireader m
geodist company juejin ireader km
geodist company juejin meituan mi
geodist company juejin jd km
geodist company juejin xiaomi km
geodist company juejin juejin km
```
  3.pos: 获取元素的经纬度位置,因为存储需要映射以及反向映射,存在一些误差,造成精度上一些损失可以接受
```shell script
geopos company juejin
geopos company ireader
geopos company juejin ireader
```
  4.hash:获取对应经纬度的hash值(可以通过网站填写路径参数,获取hash值对应的经纬度:http://geohash.org/{hash})
```shell script
geohash company ireader
geohash company juejin
```
  5.radiusbymember: 查看附近的公司(包含自己),可选参数withcoord(坐标) withdist(距离) withhash(一维整数值)
```shell script
georadiusbymember company ireader 20 km count 5 asc
georadiusbymember company ireader 20 km count 3 desc
georadiusbymember company ireader 20 km withcoord count 3 asc
georadiusbymember company ireader 20 km withdist  count 3 asc
georadiusbymember company ireader 20 km withhash  count 3 asc
georadiusbymember company ireader 20 km withcoord withdist withhash  count 3 asc
```
  6.radius: 根据经纬度查询集合内的元素
```shell script
georadius company 116.514202 39.905409 20 km withdist count 3 asc
```
  7.rem: 本质上时zset结构,可以使用rem删除元素,range遍历元素
```shell script
zrem company juejin
zrange company 0 -1
```

- note:
 redis中单个key对应的数据量不宜超过1M,因为集群环境中需要节点的数据迁移,如果key的数据过大,就会照常集群迁移出现卡顿,影响线上服务;而地图应用中,往往
 数据量过大,所以建议使用单独的redis实例部署,不适用集群环境

   