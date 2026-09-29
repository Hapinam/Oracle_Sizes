------------------------------------------------------------------------------
-- Script    : segments/top_segments.sql
-- Purpose   : Largest tables in a schema, counting the table, its indexes and
--             its LOB segments together, so the real cost of a table is
--             visible.
-- Usage     : sqlplus / as sysdba @segments/top_segments.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

SELECT owner, table_name, ROUND(SUM(bytes)/1024/1024) AS mb
FROM  (SELECT segment_name AS table_name, owner, bytes
       FROM   dba_segments
       WHERE  segment_type = 'TABLE'
       UNION ALL
       SELECT i.table_name, i.owner, s.bytes
       FROM   dba_indexes i, dba_segments s
       WHERE  s.segment_name = i.index_name
       AND    s.owner = i.owner
       AND    s.segment_type = 'INDEX'
       UNION ALL
       SELECT l.table_name, l.owner, s.bytes
       FROM   dba_lobs l, dba_segments s
       WHERE  s.segment_name = l.segment_name
       AND    s.owner = l.owner
       AND    s.segment_type = 'LOBSEGMENT'
       UNION ALL
       SELECT l.table_name, l.owner, s.bytes
       FROM   dba_lobs l, dba_segments s
       WHERE  s.segment_name = l.index_name
       AND    s.owner = l.owner
       AND    s.segment_type = 'LOBINDEX')
WHERE  owner = UPPER('&&schema_name')
GROUP  BY owner, table_name
HAVING SUM(bytes)/1024/1024 > 10          -- ignore anything under 10 MB
ORDER  BY SUM(bytes) DESC;

-- Largest segments of any type, across the whole database.
SELECT owner, segment_name, segment_type,
       ROUND(SUM(bytes)/1024/1024/1024, 2) AS gb
FROM   dba_segments
GROUP  BY owner, segment_name, segment_type
ORDER  BY SUM(bytes) DESC
FETCH FIRST 50 ROWS ONLY;                 -- 12cR1 and later

UNDEFINE schema_name
