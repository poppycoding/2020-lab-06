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
 