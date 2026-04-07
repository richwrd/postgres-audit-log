/*==============================================================================================================================================================================

  * Project: postgres-audit-log
  * Repository: https://github.com/richwrd/postgres-audit-log
  * Author: richwrd (Eduardo Richard)

  * Star this project if it helped you! | Deixe uma estrela se te ajudou!
  * Contributions welcome! | Contribuições são bem-vindas!

  * Created: July 30, 2023
  * Updated: April 07, 2026

==============================================================================================================================================================================*/

-- SETUP - AUDIT LOG SYSTEM
--
-- Master installation script for complete audit system deployment
--
-- REQUIREMENTS:
--   pg_partman must be available in the database:
--     CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;
--   (already handled in step 5 below)
--
-- MODULAR STRUCTURE:
--   1. Schema - Database structure (tables, triggers, constraints)
--   2. Core   - Business logic (audit functions and policy management)
--   3. Partman integration - Partition management via partman.part_config

-- Description:
--    Full DML audit system (Insert/Update/Delete) with:
--    - Automatic partitioning managed by pg_partman (Scalability)
--    - JSONB Data Diff (Old vs New)
--    - Security Triggers (Anti-Spoofing)
--    - Policy Management (Dynamic Triggers)

-- USAGE:
--   psql -U username -d database -f setup.sql
--
--=============================================================================================================================================================================

\echo ''
\echo '==============================================================='
\echo '   INSTALLING AUDIT LOG SYSTEM'
\echo '==============================================================='
\echo ''

-- 1. Schema (Database Structure)

\echo '> [1/5] Creating tables...'
\ir 1-schema/1.1-tables.sql
\echo '[OK] Tables created!'

\echo '> [2/5] Creating security triggers...'
\ir 1-schema/1.2-triggers.sql
\echo '[OK] Security triggers activated!'

-- 2. Core (Audit Logic)

\echo '> [3/5] Creating change recording function...'
\ir 2-core/2.1-record_change.sql
\echo '[OK] Function record_change() created!'

\echo '> [4/5] Creating policy management function...'
\ir 2-core/2.2-apply_rules.sql
\echo '[OK] Function apply_rules() created!'

-- 3. pg_partman Integration

\echo '> [5/5] Registering audit.logging_dml with pg_partman...'
\ir 2-core/2.3-partitions.sql
\echo '[OK] pg_partman configured! Partitions will be managed automatically.'
\echo ''

\echo '==============================================================='
\echo '   INSTALLATION COMPLETED SUCCESSFULLY!'
\echo '==============================================================='
\echo ''
\echo 'NEXT STEPS:'
\echo '1. Configure schemas to audit: INSERT INTO audit.log_control ...'
\echo '2. Apply rules:               SELECT audit.apply_rules();'
\echo '3. Query logs:                SELECT * FROM audit.logging_dml;'
\echo ''
\echo 'PARTITION MAINTENANCE:'
\echo '  Schedule periodically (pg_cron or OS cron):'
\echo '    SELECT partman.run_maintenance();'
\echo ''
\echo 'PARTITION CONFIGURATION:'
\echo '  SELECT * FROM partman.part_config WHERE parent_table = '"'"'audit.logging_dml'"'"';'
\echo ''
