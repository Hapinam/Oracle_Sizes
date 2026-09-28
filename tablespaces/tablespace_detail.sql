------------------------------------------------------------------------------
-- Script    : tablespaces/tablespace_detail.sql
-- Purpose   : Full picture of every tablespace including temporary ones:
--             allocated size, free space, usage against MAXSIZE, and the
--             storage attributes.
-- Usage     : sqlplus / as sysdba @tablespaces/tablespace_detail.sql
-- Requires  : SELECT_CATALOG_ROLE (reads DBA_ and V$ views)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

-- "Used of max" is the number that matters for an autoextending tablespace:
-- it is full when it reaches MAXSIZE, not when the current files are full.
SELECT ts.tablespace_name,
       ROUND(size_info.megs_alloc/1024, 2) AS "Total GB",
       ROUND(size_info.megs_free/1024, 2)  AS "Free GB",
       ROUND(size_info.megs_used/1024, 2)  AS "Used GB",
       ROUND(size_info.pct_used, 2)||'%'   AS "Used of max",
       ROUND(size_info.max/1024, 2)        AS "Max GB",
       ts.status, ts.contents, ts.logging, ts.extent_management,
       ts.allocation_type, ts.block_size, ts.segment_space_management,
       ts.force_logging, ts.bigfile, ts.def_tab_compression
FROM   (SELECT a.tablespace_name,
               ROUND(a.bytes_alloc/1024/1024)                            AS megs_alloc,
               ROUND(NVL(b.bytes_free,0)/1024/1024)                      AS megs_free,
               ROUND((a.bytes_alloc - NVL(b.bytes_free,0))/1024/1024)    AS megs_used,
               100 - ROUND((NVL(b.bytes_free,0)/a.bytes_alloc)*100)      AS pct_used,
               ROUND(a.maxbytes/1048576)                                 AS max
        FROM   (SELECT f.tablespace_name,
                       SUM(f.bytes) AS bytes_alloc,
                       SUM(DECODE(f.autoextensible,'YES',f.maxbytes,'NO',f.bytes)) AS maxbytes
                FROM   dba_data_files f
                GROUP  BY f.tablespace_name) a,
               (SELECT f.tablespace_name, SUM(f.bytes) AS bytes_free
                FROM   dba_free_space f
                GROUP  BY f.tablespace_name) b
        WHERE  a.tablespace_name = b.tablespace_name(+)
        UNION ALL
        SELECT h.tablespace_name,
               ROUND(SUM(h.bytes_free + h.bytes_used)/1048576),
               ROUND(SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used,0))/1048576),
               ROUND(SUM(NVL(p.bytes_used,0))/1048576),
               100 - ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used,0))
                            / SUM(h.bytes_used + h.bytes_free)) * 100),
               ROUND(SUM(DECODE(f.autoextensible,'YES',f.maxbytes,'NO',f.bytes)/1048576))
        FROM   v$temp_space_header h, v$temp_extent_pool p, dba_temp_files f
        WHERE  p.file_id(+) = h.file_id
        AND    p.tablespace_name(+) = h.tablespace_name
        AND    f.file_id = h.file_id
        AND    f.tablespace_name = h.tablespace_name
        GROUP  BY h.tablespace_name) size_info,
       dba_tablespaces ts
WHERE  ts.tablespace_name = size_info.tablespace_name
ORDER  BY 5 DESC;
