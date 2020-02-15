### 常用mysql辅助工具

- FIO: 检测磁盘读写工具,设置innodb_io_capacity参数
> https://www.jianshu.com/p/cb9c8807e171

- GH-HOST: 线上Online执行ddl工具,紧急情况可以主备切换做ddl,更安全保守的是使用gh-host
> https://github.com/github/gh-ost

- PT-QUERY-DIGEST: 检测sql返回结果,少量sql可以手动执行分析慢查询,当新项目sql多不适合一个个手动查看慢查询结果时,使用pt-query-digest可以分析查看慢查询
> https://www.percona.com/doc/percona-toolkit/LATEST/pt-query-digest.html