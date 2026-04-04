-- Add customer document & installation fields to pppoe_users
-- Migration: 20260227_add_pppoe_customer_docs

ALTER TABLE `pppoe_users`
  ADD COLUMN `idCardNumber` VARCHAR(50) NULL COMMENT 'NIK KTP pelanggan',
  ADD COLUMN `idCardPhoto` VARCHAR(500) NULL COMMENT 'URL foto KTP',
  ADD COLUMN `installationPhotos` JSON NULL COMMENT 'Array URL foto instalasi',
  ADD COLUMN `followRoad` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Garis ke ODP ikuti jalanan';
