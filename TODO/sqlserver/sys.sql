-- 1.统计数量
-- table
select count(*) from sysobjects  where xtype='U'
-- view
select count(*) from sysobjects  where xtype='V'
-- columns
select count(*) from syscolumns  where id =1810105489

-- 2.总数列表
select u.table_num, v.view_num, (c1.column_num1+c2.column_num2) column_num,(u.table_num + v.view_num + c1.column_num1+c2.column_num2+ 1) count_all
from
(select count(*) table_num from sysobjects where xtype='U') u,
(select count(*) view_num from sysobjects where xtype='V') v,
(select count(*) column_num1 from syscolumns where id in (select u.id from sysobjects u where xtype='U')) c1,
(select count(*) column_num2 from syscolumns where id in (select v.id from sysobjects v where xtype='V')) c2




-- 3.用户定义的数据类型基于在 Microsoft SQL Server 中提供的数据类型。当几个表中必须存储同一种数据类型时，并且为保证这些列有相同的数据类型、长度和可空性时，可以使用用户定义的数据类型。
--建自定义数据类型
Exec sp_addtype ssn,'Varchar(11)','Not Null'
--删除自定义数据类型
Exec sp_droptype 'ssn'
--查看用户自定义数据类型
select * from systypes where xtype<>xusertype
select * from sys.types where is_user_defined=1




--4.sql server 慢查询优化
SELECT TOP 10 TEXT AS 'SQL Statement'
    ,last_execution_time AS 'Last Execution Time'
    ,(total_logical_reads + total_physical_reads + total_logical_writes) / execution_count AS [Average IO]
    ,(total_worker_time / execution_count) / 1000000.0 AS [Average CPU Time (sec)]
    ,(total_elapsed_time / execution_count) / 1000000.0 AS [Average Elapsed Time (sec)]
    ,execution_count AS "Execution Count"
    ,qp.query_plan AS "Query Plan"
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY total_elapsed_time / execution_count DESC


-- DATEPART YEAR MONTH 日期截取
SELECT (SELECT MIN(MIN_DATE) FROM (VALUES (DATEPART(yyyy,TEST_DATE1)),(DATEPART(yyyy,TEST_DATE2)),(DATEPART(yyyy,TEST_DATE3))) AS #TEMP(MIN_DATE)) MIN_DATE FROM TBL
SELECT (SELECT MIN(MIN_DATE) FROM (VALUES (YEAR(TEST_DATE2)),(YEAR(TEST_DATE2)),(YEAR(TEST_DATE3))) AS #TEMP(MIN_DATE)) MIN_DATE FROM TBL
SELECT MONTH(START_DATE) FROM TBL


--ROUND 百分比
SELECT CONCAT(CAST(ROUND(5*100.0/16,2) AS NUMERIC(20,2)),'%' ) FROM TBL


--CONCAT 1 left 截取:末尾'/'
SELECT NAME LABLE, (SELECT CODE+'/' FROM TBL WHERE NAME = A.NAME FOR XML PATH('')) VALUE FROM TBL A  WHERE rank > 3 GROUP BY NAME

SELECT B.NAME,LEFT(VALUE,LEN(VALUE)-1) CODE FROM
(
SELECT NAME, (SELECT CODE+'/' FROM TBL WHERE NAME = A.NAME FOR XML PATH('')) AS VALUE FROM TBL A  WHERE rank > 3 GROUP BY NAME
) B

--CONCAT 2 stuff 替换:首端'/' ==>> "":   删除指定长度的字符并在指定的起始点插入另一组字符。
STUFF ( character_expression , start , length , character_expression )
SELECT p.NAME [value], STUFF((SELECT '/'+CODE FROM TBL WHERE NAME > 3 AND NAME = p.NAME FOR xml PATH('')),1,1,'') [label] FROM TBL p WHERE p.NAME > 3 GROUP BY p.NAME ORDER BY [value]


--STR
STR ( float_expression [ , length [ , decimal ] ] )

--日期截取,时分只需要选择对应格式,然后char/varchar截取对应的数字位: 常用8,106,23
SELECT CONVERT(varchar(5), GETDATE(), 23)
SELECT CONVERT(char(5),GETDATE(),8)
SELECT CONVERT(varchar(20), GETDATE(), 106)

--sqlServer转义like中的下划线用中括号(单引号用单引号转义)
... LIKE '%[_]d'


--sqlserver获取序列下一个值
SELECT NEXT VALUE FOR TBL_TEST_SEQ AS SEQ_ID