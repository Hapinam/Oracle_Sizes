------------------------------------------------------------------------------
-- Script    : tablespaces/tablespace_usage.sql
-- Purpose   : Used, free and percentage used for every tablespace: the first
--             thing to run when a database is reported full.
-- Usage     : sqlplus / as sysdba @tablespaces/tablespace_usage.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

-- Permanent tablespaces, largest usage first.
SELECT df.tablespace_name,
       ROUND(df.bytes/1024/1024/1024, 2)                    AS "Size GB",
       ROUND(NVL(fs.bytes,0)/1024/1024/1024, 2)             AS "Free GB",
       ROUND((df.bytes - NVL(fs.bytes,0))/1024/1024/1024, 2) AS "Used GB",
       ROUND((1 - NVL(fs.bytes,0)/df.bytes) * 100)          AS "Used %"
FROM   (SELECT tablespace_name, SUM(bytes) AS bytes
        FROM   dba_data_files GROUP BY tablespace_name) df,
       (SELECT tablespace_name, SUM(bytes) AS bytes
        FROM   dba_free_space GROUP BY tablespace_name) fs
WHERE  df.tablespace_name = fs.tablespace_name(+)
ORDER  BY 5 DESC;

-- Only the tablespaces that are nearly full.
SELECT df.tablespace_name,
       ROUND((1 - NVL(fs.bytes,0)/df.bytes) * 100) AS "Used %"
FROM   (SELECT tablespace_name, SUM(bytes) AS bytes
        FROM   dba_data_files GROUP BY tablespace_name) df,
       (SELECT tablespace_name, SUM(bytes) AS bytes
        FROM   dba_free_space GROUP BY tablespace_name) fs
WHERE  df.tablespace_name = fs.tablespace_name(+)
AND    (1 - NVL(fs.bytes,0)/df.bytes) * 100 > 85
ORDER  BY 2 DESC;

-- Usage of one tablespace, by owner, when you need to know who filled it.
SELECT s.owner, ROUND(SUM(s.bytes)/1024/1024/1024, 2) AS "Used GB"
FROM   dba_segments s
WHERE  s.tablespace_name = UPPER('&&tablespace_name')
GROUP  BY s.owner
ORDER  BY 2 DESC;

UNDEFINE tablespace_name
