------------------------------------------------------------------------------
-- Script    : segments/schema_size.sql
-- Purpose   : How much space a schema occupies, in total and per tablespace.
-- Usage     : sqlplus / as sysdba @segments/schema_size.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

SELECT tablespace_name,
       ROUND(SUM(bytes)/1024/1024) AS total_size_mb
FROM   dba_segments
WHERE  owner = UPPER('&&schema_name')
GROUP  BY ROLLUP(tablespace_name);

-- Space used by every schema, largest first: useful before a Data Pump export.
SELECT owner, ROUND(SUM(bytes)/1024/1024/1024, 2) AS gb
FROM   dba_segments
GROUP  BY owner
ORDER  BY 2 DESC;

UNDEFINE schema_name
