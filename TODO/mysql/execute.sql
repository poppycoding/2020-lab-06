
--1.查看test数据库table + view
--view
SELECT count(*) FROM information_schema.TABLES  where table_schema = 'test' and table_type = 'VIEW' GROUP BY table_schema;
--table
SELECT count(*) FROM information_schema.TABLES  where table_schema = 'test' and table_type = 'BASE TABLE' GROUP BY table_schema;
--table + view
SELECT count(*) FROM information_schema.TABLES  where table_schema = 'test' GROUP BY table_schema;
--column(table + view)
SELECT count(*) FROM information_schema.COLUMNS WHERE table_schema = 'test' [AND table_name = 'collect_job'];




--2.查看test数据库所有: db+表格+视图+列数量
SELECT
t.table_num, v.view_num, c.column_num, (t.table_num + v.view_num + c.column_num + 1) count_all
FROM
(SELECT count(*) table_num FROM information_schema.TABLES  where table_schema = 'test' and table_type = 'BASE TABLE' GROUP BY table_schema) t,
(SELECT count(*) view_num FROM information_schema.TABLES  where table_schema = 'test' and table_type = 'VIEW' GROUP BY table_schema) v,
(SELECT count(*) column_num FROM information_schema.COLUMNS WHERE table_schema = 'test') c





--3.sql查看数据库版本
select version();

