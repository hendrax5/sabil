-- Allow duplicate NAS IP addresses with different port/secret combinations
-- Drop the unique constraint on nasname
DROP INDEX `nas_nasname_key` ON `nas`;

-- Add composite unique constraint: nasname + ports + secret
ALTER TABLE `nas` 
ADD UNIQUE KEY `unique_nas_config` (`nasname`, `ports`, `secret`);
