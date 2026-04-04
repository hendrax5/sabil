-- AlterTable
ALTER TABLE `pppoe_users` ADD COLUMN `fcmTokens` TEXT NULL COMMENT 'FCM tokens for push notifications (JSON array)';
