-- Add idCardNumber and idCardPhoto to registration_requests table
ALTER TABLE `registration_requests` ADD COLUMN IF NOT EXISTS `idCardNumber` VARCHAR(20) NULL;
ALTER TABLE `registration_requests` ADD COLUMN IF NOT EXISTS `idCardPhoto` TEXT NULL;
