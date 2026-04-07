/*============================================================================================

  * Star this project if it helped you! | Deixe uma estrela se te ajudou!
  * Contributions welcome! | Contribuições são bem-vindas!

============================================================================================*/

-- PARTITION MANAGEMENT - PG_PARTMAN
--
-- This file contains:
-- - Registration of audit.logging_dml into pg_partman
-- - All partition settings consolidated in partman.part_config
-- - Automatic monthly partition creation and retention policy
--
-- REQUIREMENTS:
--   pg_partman extension must be installed:
--     CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;
--
-- MAINTENANCE:
--   Run periodically (e.g. via pg_cron or cron job):
--     SELECT partman.run_maintenance();
--
-- REFERENCE:
--   https://github.com/pgpartman/pg_partman

--============================================================================================
-- EXTENSION

CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;

--============================================================================================
-- REGISTER TABLE WITH PG_PARTMAN
--
-- partman.create_parent() bootstraps the partitioning:
--   p_parent_table   : fully qualified parent table
--   p_control        : partition key column
--   p_interval       : partition interval ('monthly', 'daily', etc.)
--   p_start_partition: first child partition boundary (ISO 8601 date string)
--   p_premake        : number of future partitions to pre-create (default 4)
--
-- After this call, ALL configuration lives in partman.part_config.

SELECT partman.create_parent(
    p_parent_table   => 'audit.logging_dml',
    p_control        => 'created_at',
    p_interval       => 'monthly',
    p_start_partition => DATE_TRUNC('month', CURRENT_DATE)::TEXT
);

--============================================================================================
-- CENTRALIZED CONFIGURATION IN partman.part_config
--
-- Adjust settings to match the audit log workload.
-- These are the only values you need to change to tune partition behaviour.

UPDATE partman.part_config
SET

    -- Pre-create N months ahead (keeps queries from ever hitting a "no partition" error)
    premake                   = 3,

    -- Automatically detect and create missing child partitions on each maintenance run
    automatic_maintenance     = 'on',

    -- Retention: keep 12 months of data online; older partitions are DROPPED automatically.
    -- Set to NULL to disable automatic drop.
    retention                 = '12 months',

    -- When a partition exceeds retention, DROP it (set to FALSE to keep it but detach it)
    retention_keep_table      = FALSE,

    -- Keep the indexes on retained tables (irrelevant when retention_keep_table = FALSE)
    retention_keep_index      = FALSE,

    -- Inherit table privileges from the parent to every new child partition
    inherit_privileges        = TRUE

WHERE parent_table = 'audit.logging_dml';

--============================================================================================
-- CONFIGURE FILLFACTOR ON EXISTING CHILD PARTITIONS
--
-- Audit logs are append-only (write-once), so fillfactor=100 eliminates the free-space
-- reservation PostgreSQL normally keeps for future updates, saving ~10-15% disk space.
--
-- pg_partman inherits this automatically from the parent's storage parameters, so we
-- only need to set it once on the parent table.

ALTER TABLE audit.logging_dml SET (fillfactor = 100);

--============================================================================================
-- INITIAL MAINTENANCE RUN
--
-- Triggers pg_partman to immediately create the bootstrap partitions defined by
-- p_start_partition and premake, instead of waiting for the next scheduled run.

SELECT partman.run_maintenance('audit.logging_dml');

--============================================================================================
-- EXECUTION EXAMPLES (for reference / manual use)

-- Run maintenance for ALL pg_partman-managed tables:
-- SELECT partman.run_maintenance();

-- Run maintenance for this table only:
-- SELECT partman.run_maintenance('audit.logging_dml');

-- Inspect current partition configuration:
-- SELECT * FROM partman.part_config WHERE parent_table = 'audit.logging_dml';

-- List all child partitions managed by pg_partman:
-- SELECT child_schema, child_tablename, partition_range
-- FROM partman.show_partitions('audit.logging_dml');