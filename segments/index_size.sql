------------------------------------------------------------------------------
-- Script    : segments/index_size.sql
-- Purpose   : Size of the indexes on a table, to see how much space the
--             indexes add to the table itself.
-- Usage     : sqlplus / as sysdba @segments/index_size.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

SELECT idx.index_name,
       idx.uniqueness,
       idx.status,
       ROUND(SUM(seg.bytes)/1024/1024/1024, 2) AS "Size GB"
FROM   dba_segments seg, dba_indexes idx
WHERE  idx.table_owner = UPPER('&&schema_name')
AND    idx.table_name  = UPPER('&&table_name')
AND    idx.owner       = seg.owner
AND    idx.index_name  = seg.segment_name
GROUP  BY idx.index_name, idx.uniqueness, idx.status
ORDER  BY 4 DESC;

UNDEFINE schema_name
UNDEFINE table_name
