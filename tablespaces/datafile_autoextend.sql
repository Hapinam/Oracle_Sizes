------------------------------------------------------------------------------
-- Script    : tablespaces/datafile_autoextend.sql
-- Purpose   : List every data and temp file with its current size, autoextend
--             increment and MAXSIZE, to find files that can no longer grow.
-- Usage     : sqlplus / as sysdba @tablespaces/datafile_autoextend.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

SELECT df.tablespace_name,
       df.file_name,
       ROUND(df.bytes/1024/1024)                   AS "Current MB",
       df.autoextensible,
       ROUND(df.increment_by * ts.block_size/1024/1024) AS "Increment MB",
       ROUND(df.maxbytes/1024/1024)                AS "Max MB",
       ROUND(df.bytes/NULLIF(df.maxbytes,0)*100)   AS "% of max"
FROM   dba_data_files df, dba_tablespaces ts
WHERE  df.tablespace_name = ts.tablespace_name
UNION ALL
SELECT tf.tablespace_name,
       tf.file_name,
       ROUND(tf.bytes/1024/1024),
       tf.autoextensible,
       ROUND(tf.increment_by * ts.block_size/1024/1024),
       ROUND(tf.maxbytes/1024/1024),
       ROUND(tf.bytes/NULLIF(tf.maxbytes,0)*100)
FROM   dba_temp_files tf, dba_tablespaces ts
WHERE  tf.tablespace_name = ts.tablespace_name
ORDER  BY 7 DESC NULLS LAST;
