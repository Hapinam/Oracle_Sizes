------------------------------------------------------------------------------
-- Script    : tablespaces/tablespace_html_report.sql
-- Purpose   : Produce an HTML tablespace usage report for the daily checks,
--             highlighting anything above 90 per cent, with sign-off boxes at
--             the end.
-- Usage     : sqlplus / as sysdba @tablespaces/tablespace_html_report.sql
-- Requires  : SELECT_CATALOG_ROLE, and a writable spool directory
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
-- WARNING   : This script spools to a local path and uses SQL*Plus HTML
--             markup, so run it from a client machine rather than on the
--             server. Set the spool directory below before running it.
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

-- Formatting for the HTML output.
SET FEEDBACK OFF
SET PAGESIZE 100
SET LINESIZE 200
SET ECHO OFF
SET HEADING ON
SET VERIFY OFF
SET MARKUP HTML ON SPOOL ON ENTMAP OFF -
     HEAD '-
     <style type="text/css"> -
        table { background: #eee; font-size: 90%; } -
        th { background: #ccc; align=center} -
        td { padding: 0px; text-align:center; vertical-align:middle;font-size:10px;font-weight: bold; } -
     </style>' -
     BODY 'text=black bgcolor=fffffff align=left' -
     TABLE 'align=center width=99% border=3 bordercolor=black bgcolor=white'

-- Where the report is written. Change this to a directory you can write to.
DEFINE report_dir = '.'

COLUMN sysdt NOPRINT NEW_VALUE sysdt
SELECT TO_CHAR(SYSDATE, 'dd-mm-yyyy') AS sysdt FROM dual;

SPOOL &report_dir/tablespaces_&sysdt..html APPEND

-- Which database, and when.
SELECT '<font size=2>'||'&_connect_identifier'||'</font>'            AS "Connect identifier",
       '<font size=2>'||instance_name||'</font>'                     AS "DB name",
       '<font size=2>'||TO_CHAR(SYSDATE,'DD.MON.YYYY HH24:MI:SS')||'</font>' AS "Current time"
FROM   v$instance;

-- Usage per tablespace; anything over 90 per cent is highlighted.
SELECT "Tablespace", "Used MB", "Free MB",
       CASE WHEN "Used %" > 90
            THEN '<p style="color: white; background-color: #666666">'||"Used %"||'</p>'
            ELSE TO_CHAR("Used %")
       END AS "USED %"
FROM (
    SELECT NVL(b.tablespace_name, NVL(a.tablespace_name,'UNKNOWN')) AS "Tablespace",
           kbytes_alloc                                             AS "Allocated MB",
           kbytes_alloc - NVL(kbytes_free,0)                        AS "Used MB",
           NVL(kbytes_free,0)                                       AS "Free MB",
           ROUND(((kbytes_alloc - NVL(kbytes_free,0))/kbytes_alloc)*100, 2) AS "Used %"
    FROM   (SELECT SUM(bytes)/1024/1024 AS kbytes_free, tablespace_name
            FROM   dba_free_space
            WHERE  tablespace_name NOT LIKE '%UNDO%'
            GROUP  BY tablespace_name) a,
           (SELECT SUM(bytes)/1024/1024 AS kbytes_alloc, tablespace_name
            FROM   dba_data_files
            WHERE  tablespace_name NOT LIKE '%UNDO%'
            GROUP  BY tablespace_name) b
    WHERE  a.tablespace_name(+) = b.tablespace_name
) ORDER BY 4 DESC;

-- Sign-off boxes, so the printed report can be reviewed and approved.
SET HEADING OFF
SELECT '<font size=4> <b>'||'Reviewed by'||' </b> </font>' FROM dual;
SELECT '<font size=2> <i>'||'Name :'||' </i> </font>', '<td width="70%">'||CHR(32)||'</td>' FROM dual
UNION
SELECT '<font size=2> <i>'||'Signature:'||' </i> </font>', '<td width="70%">'||CHR(32)||'</td>' FROM dual;

SELECT '<font size=4> <b>'||'Approved by'||' </b> </font>' FROM dual;
SELECT '<font size=2> <i>'||'Name :'||' </i> </font>', '<td width="70%">'||CHR(32)||'</td>' FROM dual
UNION
SELECT '<font size=2> <i>'||'Signature:'||' </i> </font>', '<td width="70%">'||CHR(32)||'</td>' FROM dual;

SPOOL OFF
SET MARKUP HTML OFF
SET HEADING ON
