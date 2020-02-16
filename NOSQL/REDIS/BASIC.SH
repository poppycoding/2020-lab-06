# redis5种基础数据结构: string(字符串),list(列表),set(集合),hash(哈希),zset(有序集合)

# list/set/zset/hash四种集合容器类型的数据结构,遵从两个规则:
# 1.create if not exists: 当操作容器时,不存在则创建, 2.drop if no elements 当容器没有元素时,自动删除释放内存


################################################### String ###################################################
# set(批量)
set k v
mset k1 v1 k2 v2
exists k
del k

# setnx不存在创建
setnx k v

# expire
expire k 5
setex k 5 v

# get(批量)
get k
mget k1 k2

# incr数字增减(范围long)
set age 1
incr age
incrby age 2
incrby age -2

# 字符串设置过期时间后,再次set会去掉过期时间(其他数据结构不会)
setex k 5 v
ttl k
set k v1
# -1代表不会过期
ttl k





################################################### List ###################################################
# list列表是链表相当于linkedlist结构,插入删除快O(1),查询慢O(n),当列表弹出最后一个时,自动回收内存,通常做异步队列使用.
# right push右进
rpush bs b1 b2 b3
llen bs

# 根据index(-1是倒数第一个)
lindex bs 1

# 根据index获取区间
lrange bs 0 -1

# 根据index截取区间(trim后bs列表的数据为第一个和倒数第二个之间的所有数据(闭区间),如果区间长度超范围则是清空列表)
ltrim bs 0 -2

# 队列:右进左出(先入先出)-b1
lpop bs

# 栈:右进右出(先入后出)-b3
rpop bs





################################################### Hash ###################################################
# hash相当于hashmap也是数组加链表,redis变更了rehash的策略来保证高性能,同时hash可以不像字符串一样序列化整个对象为字符串,取出也需要
# 反序列化,hash可以单独存储不同的属性,取出也可以单独取出某一个属性值,减少网络开销,但是hash结构储存消耗高于字符串

# set(value有空格时需要双引号),更新操作返回0
hset bs k1 v
hset bs k1 v1
hset bs k2 "v2 space"
hmset bs k1 v1 k2 v2 k3 v3

# getall: k-v间隔出现
hlen bs
hget bs k
hmget bs k1 k2
hgetall bs

# value增减
hincrby user age 2





################################################### Set ###################################################
# set相当于hashset无序集合,保证了k-v无序且不重复,但是这个set没有value相当于都是null,表现出来就是只有唯一的k
# 可以用来储存中奖id,保证不会重复中奖

# add
sadd bs k1
sadd bs k2 k3

# 获取size
scard bs

# get
smembers bs
sismember bs k1

# 弹出
spop bs
spop bs 2





################################################### Zset ###################################################
# zset相当于sorterSet和hashMap的结合体,保证了value的唯一性,同时添加score属性,代表排列顺序的权重,内部本职是跳跃列表的数据结构
# 可以用来保存粉丝列表,value是id,score是关注时间

# add
zadd bs 1.0 k1
zadd bs 2.0 "k2 space"
zadd bs 3.0 k3 4.1 k4

# get
zrange bs 0 -1 withscores
zrevrange bs 0 -1

# size
zcard bs

# score,rank
zscore bs k1
zrank bs k3
zrangebyscore bs 1.1 3.1
zrangebyscore bs -inf 3.1 withscores

# remove
zrem bs k1
