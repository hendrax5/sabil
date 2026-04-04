-- Standardize Status Casing Migration
-- Date: 2026-02-17
-- Purpose: Convert all status values from UPPERCASE to lowercase for consistency
--
-- Status values affected:
-- - ACTIVE → active
-- - ISOLATED → isolated
-- - BLOCKED → blocked
-- - STOP → stop

-- Update pppoe_users table
UPDATE pppoe_users SET status = 'active' WHERE status = 'ACTIVE';
UPDATE pppoe_users SET status = 'isolated' WHERE status = 'ISOLATED';
UPDATE pppoe_users SET status = 'blocked' WHERE status = 'BLOCKED';
UPDATE pppoe_users SET status = 'stop' WHERE status = 'STOP';

-- Verify status values (should only have lowercase)
-- SELECT DISTINCT status FROM pppoe_users ORDER BY status;

-- Add index if not exists (for performance)
-- Already exists in schema: @@index([status])
