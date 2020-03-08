#!/usr/bin/env bash
1.oracle数据泵
imp dms/dms@orcl  file=/home/oracle/dms.dmp ignore=y full=y;

impdp dms/dms@192.168.202.2/orcl DIRECTORY=exp_dir DUMPFILE=dms.dmp REMAP_SCHEMA=SRCUSER:user

impdp dms/dms DIRECTORY=exp_dir DUMPFILE=dms.dmp SCHEMAS=SH;

impdp DMS/dms DIRECTORY=exp_dir DUMPFILE=dms.dmp REMAP_SCHEMA=xctg:DMS

impdp DMS/dms DIRECTORY=exp_dir DUMPFILE=dms.dmp

# 创建查看逻辑目录 select * from dba_directories;
create directory exp_dir as '/home/oracle';
grant read,write on directory exp_dir to public;

# xhct gwht CTMSPROD psprd hc_xhct xctg xhd_bis,xhd_code,xhd_tos xhd
create user xhct identified by xhct;
grant dba to xhct;
create user hc_xhct identified by hc_xhct;
grant dba to hc_xhct;
create user psprd identified by psprd;
grant dba to psprd;
create user gwht identified by gwht;
grant dba to gwht;
create user CTMSPROD identified by CTMSPROD;
grant dba to CTMSPROD;
create user xhd identified by xhd;
grant dba to xhd;
create user xctg identified by xctg;
grant dba to xctg;
create user xhd_bis identified by xhd_bis;
grant dba to xhd_bis;
create user xhd_code identified by xhd_code;
grant dba to xhd_code;
create user xhd_tos identified by xhd_tos;
grant dba to xhd_tos;

drop user xhct cascade;
drop user hc_xhct cascade;
drop user psprd cascade;
drop user gwht cascade;
drop user CTMSPROD cascade;
drop user xhd_bis cascade;
drop user xhd_code cascade;
drop user xhd_tos cascade;
drop user xctg cascade;

/oradata/neworcl

create tablespace PDW_XCGT datafile '/oradata/neworcl/pdw_xcgt_tbs.dbf' size 100M autoextend on maxsize 16g;
alter tablespace PDW_XCGT add datafile '/oradata/neworcl/pdw_xcgt_tbs01.dbf' size 100M autoextend on maxsize 16g;
alter tablespace PDW_XCGT add datafile '/oradata/neworcl/pdw_xcgt_tbs02.dbf' size 100M autoextend on maxsize 16g;
create tablespace ODS_GWHT datafile '/oradata/neworcl/ods_gwht_tbs.dbf' size 100M autoextend on maxsize 16g;
create tablespace ODS_PSPRD datafile '/oradata/neworcl/ods_psprd_tbs.dbf' size 100M autoextend on maxsize 16g;
create tablespace ODS_HC_XHCT datafile '/oradata/neworcl/ods_xhct_tbs.dbf' size 100M autoextend on maxsize 16g;
create tablespace JZX datafile '/oradata/neworcl/jzx_tbs.dbf' size 100M autoextend on maxsize 16g;
create tablespace ODS_XCGT      datafile  '/oradata/neworcl/tbs_ODS_XCGT.dbf'    size 100m autoextend on maxsize 16g;
create tablespace ODS_DDHX   datafile  '/oradata/neworcl/tbs_ODS_DDHX.dbf'    size 100m autoextend on maxsize 16g;
create tablespace ODS_XHCT   datafile  '/oradata/neworcl/tbs_ODS_XHCT.dbf'    size 100m autoextend on maxsize 16g;
create tablespace ODS_HC_XHCT   datafile  '/oradata/neworcl/tbs_ODS_HC_XHCT.dbf' size 100m autoextend on maxsize 16g;
create tablespace ODS_GWHT   datafile  '/oradata/neworcl/tbs_ODS_GWHT.dbf'    size 100m autoextend on maxsize 16g;
create tablespace ODS_PSPRD   datafile  '/oradata/neworcl/tbs_ODS_PSPRD.dbf'   size 100m autoextend on maxsize 16g;
create tablespace ODS_XHD   datafile  '/oradata/neworcl/tbs_ODS_XHD.dbf'     size 100m autoextend on maxsize 16g;
create tablespace JZX   datafile  '/oradata/neworcl/tbs_JZX.dbf'         size 100m autoextend on maxsize 16g;
create tablespace ODS_XYZX   datafile  '/oradata/neworcl/tbs_ODS_XYZX.dbf'    size 100m autoextend on maxsize 16g;
create tablespace ODS_HCBSYQ   datafile  '/oradata/neworcl/tbs_ODS_HCBSYQ.dbf'  size 100m autoextend on maxsize 16g;
create tablespace TEST   datafile  '/oradata/neworcl/tbs_TEST.dbf'        size 100m autoextend on maxsize 16g;
create tablespace ODS_XHCTDW   datafile  '/oradata/neworcl/tbs_ODS_XHCTDW.dbf'  size 100m autoextend on maxsize 16g;
create tablespace ODS_EIR   datafile  '/oradata/neworcl/tbs_ODS_EIR.dbf'     size 100m autoextend on maxsize 16g;
create tablespace SYSTEM   datafile  '/oracle/app/oradata/neworcl/system02.dbf'     size 100m autoextend on maxsize 16g;

create user CTMSPROD  identified by CTMSPROD;
create user CTXSYS  identified by CTXSYS;
create user DBSNMP  identified by DBSNMP;
create user DDHX  identified by DDHX;
create user DIP  identified by DIP;
create user DZKA  identified by DZKA;
create user EAM_DW  identified by EAM_DW;
create user EXFSYS  identified by EXFSYS;
create user FLOWS_FILES  identified by FLOWS_FILES;
create user GWHT  identified by GWHT;
create user HCBSYQ  identified by HCBSYQ;
create user HC_XHCT  identified by HC_XHCT;
create user K3  identified by K3;
create user MDDATA  identified by MDDATA;
create user MDSYS  identified by MDSYS;
create user MGMT_VIEW  identified by MGMT_VIEW;
create user OA  identified by OA;
create user ODC  identified by ODC;
create user ODS_HXMT  identified by ODS_HXMT;
create user OLAPSYS  identified by OLAPSYS;
create user ORACLE_OCM  identified by ORACLE_OCM;
create user ORDDATA  identified by ORDDATA;
create user ORDPLUGINS  identified by ORDPLUGINS;
create user ORDSYS  identified by ORDSYS;
create user OUTLN  identified by OUTLN;
create user OWBSYS  identified by OWBSYS;
create user OWBSYS_AUDIT  identified by OWBSYS_AUDIT;
create user PSPRD  identified by PSPRD;
create user SCOTT  identified by SCOTT;
create user SEMP_XCTG  identified by SEMP_XCTG;
create user SI_INFORMTN_SCHEMA  identified by SI_INFORMTN_SCHEMA;
create user SPATIAL_CSW_ADMIN_USR  identified by SPATIAL_CSW_ADMIN_USR;
create user SPATIAL_WFS_ADMIN_USR  identified by SPATIAL_WFS_ADMIN_USR;
create user SYS  identified by SYS;
create user SYSMAN  identified by SYSMAN;
create user SYSTEM  identified by SYSTEM;
create user TEST_USER  identified by TEST_USER;
create user WMSYS  identified by WMSYS;
create user XCTG  identified by XCTG;
create user XCTG_BI  identified by XCTG_BI;
create user XDB  identified by XDB;
create user XHCT  identified by XHCT;
create user XHCTDW  identified by XHCTDW;
create user XHD  identified by XHD;
create user XHD_BIS  identified by XHD_BIS;
create user XHD_CODE  identified by XHD_CODE;
create user XHD_TOS  identified by XHD_TOS;
create user XHD_TOS_HIS  identified by XHD_TOS_HIS;
create user XICT  identified by XICT;
grant dba to CTMSPROD;
grant dba to GWHT;
grant dba to HCBSYQ;
grant dba to HC_XHCT;
grant dba to XHCT;
grant dba to XHD;
grant dba to PSPRD;
grant dba to DDHX;
grant dba to DIP;
grant dba to DZKA;
grant dba to EAM_DW;
grant dba to EXFSYS;
grant dba to FLOWS_FILES;
grant dba to K3;
grant dba to MGMT_VIEW;
grant dba to OA;
grant dba to ODC;
grant dba to ODS_HXMT;
grant dba to OLAPSYS;
grant dba to SEMP_XCTG;
grant dba to SI_INFORMTN_SCHEMA;
grant dba to SPATIAL_CSW_ADMIN_USR;
grant dba to SPATIAL_WFS_ADMIN_USR;
grant dba to TEST_USER;
grant dba to WMSYS;
grant dba to XCTG_BI;
grant dba to XCTG;
grant dba to XDB;
grant dba to XHCTDW;
grant dba to XHD_BIS;
grant dba to XHD_CODE;
grant dba to XHD_TOS;
grant dba to XHD_TOS_HIS;
grant dba to XICT;


# 导出:
expdp xctg/Oracle123@orcl  directory=dir content=metadata_only schemas=xhct dumpfile=xhct.dmp


# 导入:




impdp xhct/XHCT          directory=exp_dir dumpfile=xhct.dmp      logfile=xhct.log      content=metadata_only EXCLUDE=STATISTICS
impdp CTMSPROD/CTMSPROD  directory=exp_dir dumpfile=CTMSPROD.dmp  logfile=CTMSPROD.log  content=metadata_only EXCLUDE=STATISTICS
impdp xhd_tos/XHD_TOS    directory=exp_dir dumpfile=xhd_tos.dmp   logfile=xhd_tos.log   content=metadata_only EXCLUDE=STATISTICS
impdp xhd_code/XHD_CODE  directory=exp_dir dumpfile=xhd_code.dmp  logfile=xhd_code.log  content=metadata_only EXCLUDE=STATISTICS
impdp xhd_bis/XHD_BIS    directory=exp_dir dumpfile=xhd_bis.dmp   logfile=xhd_bis.log   content=metadata_only EXCLUDE=STATISTICS
impdp gwht/GWHT          directory=exp_dir dumpfile=gwht.dmp      logfile=gwht.log      content=metadata_only EXCLUDE=STATISTICS
impdp hc_xhct/HC_XHCT    directory=exp_dir dumpfile=hc_xhct.dmp   logfile=hc_xhct.log   content=metadata_only EXCLUDE=STATISTICS
impdp psprd/PSPRD        directory=exp_dir dumpfile=psprd.dmp     logfile=psprd.log     content=metadata_only EXCLUDE=STATISTICS

impdp XCTG/XCTG          directory=exp_dir dumpfile=xctg.dmp      logfile=xctg.log      content=metadata_only






ps -ef | grep redis | grep -v grep | awk '{print $2}' | xargs kill -9









