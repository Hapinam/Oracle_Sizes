# Oracle Sizes

Scripts for answering the space questions an Oracle DBA is asked every week:
how big is the database, which tablespace is about to fill up, which table is
eating the disk, how much room is left in ASM, and how fast is any of it
growing.

## Contents

- [Requirements](#requirements)
- [How to use these scripts](#how-to-use-these-scripts)
- [Where to start](#where-to-start)
- [Script index](#script-index)
- [Conventions](#conventions)
- [Contributing](#contributing)
- [Licence](#licence)

## Requirements

- Oracle Database 11gR2 or later. Used on 11gR2, 12cR1 and 12cR2; the scripts
  work unchanged on 19c apart from `FETCH FIRST`, which needs 12cR1 or later.
- SQL*Plus or SQLcl. There is nothing to install.
- An account that can read the data dictionary: `SELECT_CATALOG_ROLE` is enough
  for everything except `growth/db_space_history.sql`, which creates objects,
  and the ASM script, which reads the `V$ASM_*` views.

## How to use these scripts

```bash
git clone https://github.com/hapinam/Oracle_Sizes.git
cd Oracle_Sizes
sqlplus / as sysdba @tablespaces/tablespace_usage.sql
```

Scripts prompt for the schema, table or tablespace they need:

```sql
SQL> @segments/table_size.sql
Enter value for schema_name: APP_OWNER
Enter value for table_name: ORDERS
```

## Where to start

| Question | Script |
| --- | --- |
| "The database is full." | [`tablespaces/tablespace_usage.sql`](tablespaces/tablespace_usage.sql) |
| "Can this tablespace still grow?" | [`tablespaces/datafile_autoextend.sql`](tablespaces/datafile_autoextend.sql) |
| "What is using the space?" | [`segments/top_segments.sql`](segments/top_segments.sql) |
| "How big is the whole database?" | [`database/database_size.sql`](database/database_size.sql) |
| "How fast is it growing?" | [`database/growth_per_month.sql`](database/growth_per_month.sql), then install [`growth/db_space_history.sql`](growth/db_space_history.sql) |
| "How much room is left in ASM?" | [`asm/diskgroups.sql`](asm/diskgroups.sql) |
| "I need a report for the daily checks." | [`tablespaces/tablespace_html_report.sql`](tablespaces/tablespace_html_report.sql) |

Two things worth remembering when reading the output:

- For an autoextending tablespace, the useful number is usage against
  **MAXSIZE**, not against the current file size. `tablespace_detail.sql` shows
  both.
- In ASM, watch **USABLE_FILE_MB** rather than free space: it already subtracts
  what is needed to rebuild after losing a failure group.

## Script index

### Whole database (`database/`)

| Script | What it does | Caution |
| --- | --- | --- |
| [`database_size.sql`](database/database_size.sql) | Total size of the database on disk (data, temp, redo and control files), and how much of it is free. |  |
| [`growth_per_month.sql`](database/growth_per_month.sql) | Show how much the database has grown each month over the last year, based on datafile creation times. |  |

### Tablespaces and datafiles (`tablespaces/`)

| Script | What it does | Caution |
| --- | --- | --- |
| [`datafile_autoextend.sql`](tablespaces/datafile_autoextend.sql) | List every data and temp file with its current size, autoextend increment and MAXSIZE, to find files that can no longer grow. |  |
| [`tablespace_detail.sql`](tablespaces/tablespace_detail.sql) | Full picture of every tablespace including temporary ones: allocated size, free space, usage against MAXSIZE, and the storage attributes. |  |
| [`tablespace_html_report.sql`](tablespaces/tablespace_html_report.sql) | Produce an HTML tablespace usage report for the daily checks, highlighting anything above 90 per cent, with sign-off boxes at the end. | read the warning in the header |
| [`tablespace_usage.sql`](tablespaces/tablespace_usage.sql) | Used, free and percentage used for every tablespace: the first thing to run when a database is reported full. |  |

### Tables, indexes and schemas (`segments/`)

| Script | What it does | Caution |
| --- | --- | --- |
| [`index_size.sql`](segments/index_size.sql) | Size of the indexes on a table, to see how much space the indexes add to the table itself. |  |
| [`schema_size.sql`](segments/schema_size.sql) | How much space a schema occupies, in total and per tablespace. |  |
| [`table_size.sql`](segments/table_size.sql) | Size of one table, including its partitions and the tablespaces they live in. |  |
| [`top_segments.sql`](segments/top_segments.sql) | Largest tables in a schema, counting the table, its indexes and its LOB segments together, so the real cost of a table is visible. |  |

### ASM (`asm/`)

| Script | What it does | Caution |
| --- | --- | --- |
| [`diskgroups.sql`](asm/diskgroups.sql) | Free and usable space in each ASM disk group, and the state of the disks behind them. |  |

### Growth history (`growth/`)

| Script | What it does | Caution |
| --- | --- | --- |
| [`db_space_history.sql`](growth/db_space_history.sql) | Install a weekly job that records the size of the database, so growth can be reported from real history instead of estimated from datafile dates. | read the warning in the header |


## Conventions

- Every script starts with the same header block: script name, purpose, usage,
  required privileges, the versions it was used on, and a warning when it is
  not purely read-only.
- Schema, table and tablespace names are SQL*Plus substitution variables
  (`&&schema_name`, `&&table_name`, `&&tablespace_name`), so no script is tied
  to one environment.
- Sizes are reported in MB or GB with the unit in the column heading, never in
  raw bytes.
- Directories group scripts by what they measure: `database/`, `tablespaces/`,
  `segments/`, `asm/`, `growth/`.

`tools/check_repo.sh` enforces the mechanical part (headers present, LF line
endings, no credential patterns, no private IP addresses) and runs in CI on
every push and pull request:

```bash
./tools/check_repo.sh
```

## Contributing

Pull requests are welcome. Keep the header block, use substitution variables
rather than environment specific names, and run `./tools/check_repo.sh` before
opening the request.

## Licence

Released under the MIT Licence. Copyright (c) 2026 Mohamed Dawood.
See [LICENSE](LICENSE).
