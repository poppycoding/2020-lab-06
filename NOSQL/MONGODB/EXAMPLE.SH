# 导入数据
# 下载解压dump数据,到../Backup文件夹
curl -O -k https://raw.githubusercontent.com/tapdata/geektimemongodb-course/master/aggregation/dump.tar.gz
tar -xvf dump.tar.gz

# Backup目录下执行restore,恢复dump文件
mongorestore -h localhost:27017