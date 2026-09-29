------------------------------------------------------------------------------
-- Script    : asm/diskgroups.sql
-- Purpose   : Free and usable space in each ASM disk group, and the state of
--             the disks behind them.
-- Usage     : sqlplus / as sysdba @asm/diskgroups.sql
-- Requires  : SELECT on the V$ASM views, normally from the Grid
--             Infrastructure home or as SYSDBA/SYSASM
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

-- Watch USABLE_FILE_MB rather than FREE_MB: it already subtracts the space
-- needed to rebuild after losing a failure group.
SELECT name,
       ROUND(total_mb/1024)         AS total_gb,
       ROUND(free_mb/1024)          AS free_gb,
       ROUND(usable_file_mb/1024)   AS usable_gb,
       ROUND(100 - free_mb/total_mb*100)||'%' AS used,
       type                         AS redundancy,
       state
FROM   v$asm_diskgroup;

-- The disks of each group, with their status and path.
SELECT g.name AS diskgroup, d.name AS disk, d.path,
       d.mount_status, d.header_status, d.mode_status, d.state,
       ROUND(d.total_mb/1024) AS total_gb,
       ROUND(d.free_mb/1024)  AS free_gb,
       d.failgroup
FROM   v$asm_disk d, v$asm_diskgroup g
WHERE  d.group_number = g.group_number
ORDER  BY g.name, d.name;
