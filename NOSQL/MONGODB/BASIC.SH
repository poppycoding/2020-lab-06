# ================================ System(V4.0) ================================


# ===================== INSERT
db.fruit.insertOne({name: "apple"})
db.fruit.insertMany([{name: "apple"}, {name: "pear"}, {name: "orange"}])
db.movies.insertOne( {
"title" : "Raiders of the Lost Ark",
"filming_locations" : [
{ "city" : "Los Angeles", "state" : "CA", "country" : "USA" },
{ "city" : "Rome", "state" : "Lazio", "country" : "Italy" },
{ "city" : "Florence", "state" : "SC", "country" : "USA" } ] })


# ===================== SELECT
# projection投影
db.movies.find({"category": "action"},{"_id":0, title:1})
# 单条件查询
db.movies.find( { "year" : 1975 } )
# 多条件 and 查询
db.movies.find( { "year" : 1989, "title" : "Batman" } )
# and 的另一种形式
db.movies.find( { $and : [ {"title" : "Batman"}, { "category" : "action" }] } )
# 多条件 or 查询
db.movies.find( { $or: [{"year" : 1989}, {"title" : "Batman"}] } )
# 按正则表达式查找
db.movies.find( { "title" : /^B/} )
# ...
db.movies.find({"filming_locations.city": "Rome"})
db.getCollection('movies').find({ "filming_locations": { $elemMatch:{"city":"Rome", "country": "USA"} } })


# ===================== UPDATE
db.fruit.updateOne({name: "apple"}, {$set: {from: "China"}})


# ===================== DELETE
# 删除a 等于1的记录
db.testcol.remove( { a : 1 } )
# 删除a 小于5的记录
db.testcol.remove( { a : { $lt : 5 } } )
# 删除所有记录
db.testcol.remove( { } )


# ===================== AGGREGATION
# SELECT FIRST_NAME AS `名`, LAST_NAME AS `姓` FROM Users WHERE GENDER = '男' SKIP 100 LIMIT 20
db.users.aggregate([
{$match: {gender: "男"}},
{$skip: 100}, {$limit: 20},
{$project: { '名': '$first_name', '姓': '$last_name' }}]);

# SELECT DEPARTMENT, COUNT(NULL) AS EMP_QTY FROM Users WHERE GENDER = '女' GROUP BY DEPARTMENT HAVING COUNT(*) < 10
db.users.aggregate([
{$match: {gender: '女'}},
{$group: {
_id: '$DEPARTMENT', emp_qty: {$sum: 1} }},
{$match: {emp_qty: {$lt: 10}}}]);

# unwind
db.students.findOne();
{name:'张三',
score:[
{subject:'语文',score:84},
{subject:'数学',score:90},
{subject:'外语',score:69} ] }

db.students.aggregate([{$unwind: '$score'}]);
{name: '张三', score: {subject: '语文', score: 84}}
{name: '张三', score: {subject: '数学', score: 90}}
{name: '张三', score: {subject: '外语', score: 69}}

# $bucket
db.products.aggregate([{
$bucket:{
groupBy: "$price",
boundaries: [0,10,20,30,40],
default: "Other",
output:{"count":{$sum:1}} } }])

# $facet
db.products.aggregate([{
$facet:{ price:{ $bucket:{…} }, year:{ $bucket:{…} } } }])


# ===================== OTHER
# 删除db
use tempDB
db.dropDatabase()

# 删除collection
db.colToBeDropped.drop()
