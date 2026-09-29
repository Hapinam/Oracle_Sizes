------------------------------------------------------------------------------
-- Script    : segments/table_size.sql
-- Purpose   : Size of one table, including its partitions and the tablespaces
--             they live in.
-- Usage     : sqlplus / as sysdba @segments/table_size.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

-- Segments whose name matches the table.
SELECT owner, segment_name, segment_type, tablespace_name,
       ROUND(bytes/1024/1024) AS mb
FROM   dba_segments
WHERE  owner = UPPER('&&schema_name')
AND    segment_name LIKE UPPER('%&&table_name%')
ORDER  BY bytes DESC;

-- Broken down by partition.
SELECT owner, segment_name, partition_name, tablespace_name,
       ROUND(bytes/1024/1024) AS mb
FROM   dba_segments
WHERE  owner = UPPER('&&schema_name')
AND    segment_type IN ('TABLE','TABLE PARTITION','INDEX','INDEX PARTITION')
AND    segment_name LIKE UPPER('%&&table_name%')
ORDER  BY segment_name, bytes DESC;

-- Number of rows and blocks as the optimizer sees them; stale statistics make
-- these numbers wrong, so compare them with the segment size above.
SELECT owner, table_name, num_rows, blocks, avg_row_len, last_analyzed
FROM   dba_tables
WHERE  owner = UPPER('&&schema_name')
AND    table_name LIKE UPPER('%&&table_name%');

UNDEFINE schema_name
UNDEFINE table_name
