------------------------------------------------------------------------------
-- Script    : database/growth_per_month.sql
-- Purpose   : Show how much the database has grown each month over the last
--             year, based on datafile creation times.
-- Usage     : sqlplus / as sysdba @database/growth_per_month.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

-- A rough but instant growth history: it only counts files added, so it
-- misses growth by autoextend. For an accurate history, install
-- growth/db_space_history.sql.
SELECT TO_CHAR(creation_time, 'RRRR MM Month') AS month,
       ROUND(SUM(bytes)/1024/1024/1024)        AS "Growth GB"
FROM   v$datafile
WHERE  creation_time > SYSDATE - 365
GROUP  BY TO_CHAR(creation_time, 'RRRR MM Month')
ORDER  BY 1;
