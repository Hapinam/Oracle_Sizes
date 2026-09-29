------------------------------------------------------------------------------
-- Script    : growth/db_space_history.sql
-- Purpose   : Install a weekly job that records the size of the database, so
--             growth can be reported from real history instead of estimated
--             from datafile dates.
-- Usage     : sqlplus / as sysdba @growth/db_space_history.sql
-- Requires  : SYSDBA (creates a table, a procedure and a scheduler job)
-- Tested on : Oracle Database 11gR2, 12cR1 and 12cR2
-- WARNING   : This creates objects in the schema you are connected as. UNDO
--             and temporary tablespaces are deliberately excluded, so the
--             figures are data and indexes only.
--
-- Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
------------------------------------------------------------------------------

-- 1. History table.
CREATE TABLE db_space_hist (
    timestamp          DATE,
    total_space_in_gb  NUMBER(8),
    used_space_in_gb   NUMBER(8),
    free_space_in_gb   NUMBER(8),
    pct_inuse          NUMBER(5,2),
    num_db_files       NUMBER(5)
);

-- 2. Procedure that adds one row for the current size.
CREATE OR REPLACE PROCEDURE db_space_history AS
BEGIN
   INSERT INTO db_space_hist
   SELECT SYSDATE,
          total_space,
          total_space - NVL(free_space,0),
          NVL(free_space,0),
          ((total_space - NVL(free_space,0)) / total_space) * 100,
          num_db_files
   FROM ( SELECT SUM(bytes)/1024/1024/1024 AS free_space
          FROM   dba_free_space
          WHERE  tablespace_name NOT LIKE '%UNDO%' ) free,
        ( SELECT SUM(bytes)/1024/1024/1024 AS total_space,
                 COUNT(*) AS num_db_files
          FROM   dba_data_files
          WHERE  tablespace_name NOT LIKE '%UNDO%' ) full_size;
   COMMIT;
END;
/

-- 3. Weekly job. Adjust the start date and time zone to suit the database.
BEGIN
  DBMS_SCHEDULER.create_job(
     job_name        => 'DB_SPACE_HISTORY_JOB'
    ,start_date      => SYSTIMESTAMP
    ,repeat_interval => 'freq=weekly; byhour=2; byminute=0; bysecond=0;'
    ,end_date        => NULL
    ,job_class       => 'DEFAULT_JOB_CLASS'
    ,job_type        => 'PLSQL_BLOCK'
    ,job_action      => 'BEGIN db_space_history(); END;'
    ,comments        => 'Weekly record of database size');

  DBMS_SCHEDULER.set_attribute('DB_SPACE_HISTORY_JOB', 'RESTARTABLE', FALSE);
  DBMS_SCHEDULER.set_attribute('DB_SPACE_HISTORY_JOB', 'LOGGING_LEVEL',
                               DBMS_SCHEDULER.logging_runs);
  DBMS_SCHEDULER.set_attribute('DB_SPACE_HISTORY_JOB', 'JOB_PRIORITY', 3);
  DBMS_SCHEDULER.set_attribute('DB_SPACE_HISTORY_JOB', 'AUTO_DROP', FALSE);
  DBMS_SCHEDULER.enable('DB_SPACE_HISTORY_JOB');
END;
/

-- 4. Read the history.
SELECT timestamp, total_space_in_gb, used_space_in_gb, free_space_in_gb,
       pct_inuse, num_db_files
FROM   db_space_hist
ORDER  BY timestamp DESC;

-- Growth between consecutive records.
SELECT timestamp,
       used_space_in_gb,
       used_space_in_gb - LAG(used_space_in_gb)
                          OVER (ORDER BY timestamp) AS "Growth GB"
FROM   db_space_hist
ORDER  BY timestamp;

-- To remove the job again:
-- EXEC DBMS_SCHEDULER.drop_job('DB_SPACE_HISTORY_JOB');
