------------------------------------------------------------------------------
-- Script    : database/database_size.sql
-- Purpose   : Total size of the database on disk (data, temp, redo and
--             control files), and how much of it is free.
-- Usage     : sqlplus / as sysdba @database/database_size.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

-- Allocated: everything the database has taken from the file systems or ASM.
SELECT ROUND(
         (SELECT SUM(bytes)/1024/1024/1024 FROM dba_data_files)
       + (SELECT NVL(SUM(bytes),0)/1024/1024/1024 FROM dba_temp_files)
       + (SELECT SUM(bytes)/1024/1024/1024 FROM v$log)
       + (SELECT SUM(block_size*file_size_blks)/1024/1024/1024 FROM v$controlfile)
       , 2) AS "Allocated GB"
FROM   dual;

-- Free: space inside that allocation which is not used by any segment.
SELECT ROUND(
         (SELECT SUM(bytes)/1024/1024/1024 FROM dba_free_space)
       + (SELECT SUM(free_space)/1024/1024/1024 FROM dba_temp_free_space)
       , 2) AS "Free GB"
FROM   dual;

-- Used: what the segments actually hold.
SELECT ROUND(SUM(bytes)/1024/1024/1024, 2) AS "Used GB"
FROM   dba_segments;
