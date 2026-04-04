-- DropIndex: Remove unique constraint from nasname
-- Allow same IP with different port/secret combinations

-- Drop the unique constraint on nasname
ALTER TABLE `nas` DROP INDEX `nas_nasname_key`;

-- Create composite unique index on nasname + ports + secret
-- This allows multiple NAS with same IP but different port or secret
ALTER TABLE `nas` ADD UNIQUE INDEX `nas_nasname_ports_secret_key` (`nasname`, `ports`, `secret`);
