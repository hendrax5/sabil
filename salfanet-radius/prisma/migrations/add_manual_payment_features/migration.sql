-- Migration: Add Manual Payment & Enhanced Features
-- Date: December 19, 2025
-- Description: Add manual payment system, subscription types, bank accounts, and batch processing

-- 1. Add fields to company table
ALTER TABLE `companies` 
ADD COLUMN `bankAccounts` JSON COMMENT 'Array of bank account objects: [{bankName, accountNumber, accountName}]',
ADD COLUMN `invoiceGenerateDays` INT DEFAULT 7 COMMENT 'Days before expiry to generate invoice';

-- 2. Add fields to pppoe_users table
ALTER TABLE `pppoe_users`
ADD COLUMN `customer_id` VARCHAR(8) UNIQUE COMMENT 'Unique 8-digit customer identifier',
ADD COLUMN `subscriptionType` ENUM('POSTPAID', 'PREPAID') NOT NULL DEFAULT 'POSTPAID',
ADD COLUMN `lastPaymentDate` DATETIME COMMENT 'Last payment date for tracking',
ADD INDEX `idx_subscriptionType` (`subscriptionType`);

-- 3. Add GPS coordinates to registration_requests
ALTER TABLE `registration_requests`
ADD COLUMN `latitude` FLOAT COMMENT 'GPS latitude of customer location',
ADD COLUMN `longitude` FLOAT COMMENT 'GPS longitude of customer location';

-- 4. Add batch processing fields to whatsapp_reminder_settings
ALTER TABLE `whatsapp_reminder_settings`
ADD COLUMN `batchSize` INT NOT NULL DEFAULT 10 COMMENT 'Number of messages per batch',
ADD COLUMN `batchDelay` INT NOT NULL DEFAULT 60 COMMENT 'Delay between batches in seconds',
ADD COLUMN `randomize` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Randomize message order';

-- 5. Create manual_payments table
CREATE TABLE IF NOT EXISTS `manual_payments` (
  `id` VARCHAR(191) NOT NULL PRIMARY KEY,
  `userId` VARCHAR(191) NOT NULL,
  `invoiceId` VARCHAR(191) NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `paymentDate` DATETIME NOT NULL,
  `bankName` VARCHAR(191) NOT NULL COMMENT 'Bank used for transfer',
  `accountName` VARCHAR(191) NOT NULL COMMENT 'Sender account name',
  `receiptImage` VARCHAR(191) COMMENT 'Path to uploaded receipt image',
  `notes` TEXT COMMENT 'Additional notes from customer',
  `status` ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
  `approvedBy` VARCHAR(191) COMMENT 'Admin user ID who approved/rejected',
  `approvedAt` DATETIME COMMENT 'Approval/rejection timestamp',
  `rejectionReason` TEXT COMMENT 'Reason for rejection',
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL,
  INDEX `idx_userId` (`userId`),
  INDEX `idx_invoiceId` (`invoiceId`),
  INDEX `idx_status` (`status`),
  INDEX `idx_paymentDate` (`paymentDate`),
  CONSTRAINT `manual_payments_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `pppoe_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `manual_payments_invoiceId_fkey` FOREIGN KEY (`invoiceId`) REFERENCES `invoices`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Create uploads directory for payment proofs
-- Note: This needs to be done via file system
-- mkdir -p public/uploads/payment-proofs

-- 7. Add email and WhatsApp templates for manual payment
INSERT INTO `whatsapp_templates` (`id`, `name`, `type`, `message`, `isActive`, `createdAt`, `updatedAt`) 
VALUES 
(
  REPLACE(UUID(), '-', ''),
  'Manual Payment Approval',
  'manual-payment-approval',
  '✅ *Pembayaran Diterima*

Halo *{{customerName}}*,

Terima kasih! Pembayaran Anda telah kami terima dan diverifikasi.

📋 *Detail Pembayaran:*
━━━━━━━━━━━━━━━━━━
📄 Invoice: *{{invoiceNumber}}*
💰 Jumlah: *{{amount}}*
📅 Masa Aktif: hingga *{{expiredDate}}*
━━━━━━━━━━━━━━━━━━

✨ Status akun Anda telah diaktifkan kembali dan dapat digunakan.

Terima kasih telah mempercayai layanan kami! 🙏

📞 Butuh bantuan? Hubungi: {{companyPhone}}
{{companyName}}',
  TRUE,
  NOW(),
  NOW()
),
(
  REPLACE(UUID(), '-', ''),
  'Manual Payment Rejection',
  'manual-payment-rejection',
  '❌ *Pembayaran Ditolak*

Halo *{{customerName}}*,

Mohon maaf, bukti pembayaran Anda untuk invoice *{{invoiceNumber}}* tidak dapat diverifikasi.

📋 *Alasan Penolakan:*
{{rejectionReason}}

🔄 *Langkah Selanjutnya:*
Silakan upload ulang bukti transfer yang valid melalui link berikut:
{{paymentLink}}

*Pastikan:*
- Foto bukti transfer jelas dan terbaca
- Jumlah transfer sesuai dengan tagihan
- Tanggal transfer tercantum

📞 Butuh bantuan? Hubungi: {{companyPhone}}
{{companyName}}',
  TRUE,
  NOW(),
  NOW()
),
(
  REPLACE(UUID(), '-', ''),
  'Maintenance Outage',
  'maintenance-outage',
  '⚠️ *Informasi Gangguan Jaringan*

Halo *{{customerName}}*,

Kami informasikan bahwa saat ini terjadi gangguan pada jaringan internet kami.

📋 *Detail Gangguan:*
━━━━━━━━━━━━━━━━━━
🔧 Jenis: *{{issueType}}*
📍 Area Terdampak: *{{affectedArea}}*
📝 Keterangan: {{description}}
⏰ Estimasi Pemulihan: *{{estimatedTime}}*
━━━━━━━━━━━━━━━━━━

🔄 *Status:* Sedang dalam perbaikan

Tim teknis kami sedang bekerja untuk mengatasi gangguan ini secepat mungkin. 
Kami mohon maaf atas ketidaknyamanan yang ditimbulkan.

📌 *Update:*
Kami akan menginformasikan kembali jika layanan sudah pulih normal.

📞 Butuh bantuan? Hubungi: {{companyPhone}}

Terima kasih atas pengertian Anda.
{{companyName}} 🙏',
  TRUE,
  NOW(),
  NOW()
);

-- 8. Add email templates for manual payment
INSERT INTO `email_templates` (`id`, `name`, `type`, `subject`, `htmlBody`, `isActive`, `createdAt`, `updatedAt`)
VALUES
(
  REPLACE(UUID(), '-', ''),
  'Manual Payment Approval',
  'manual-payment-approval',
  '✅ Pembayaran Invoice {{invoiceNumber}} Diterima',
  '<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .success-box { background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0; border-radius: 5px; }
    .info-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    .info-table td { padding: 10px; border-bottom: 1px solid #ddd; }
    .info-table td:first-child { font-weight: bold; width: 40%; }
    .footer { text-align: center; margin-top: 30px; padding: 20px; color: #666; font-size: 14px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✅ Pembayaran Diterima</h1>
    </div>
    <div class="content">
      <p>Halo <strong>{{customerName}}</strong>,</p>
      
      <div class="success-box">
        <strong>🎉 Selamat!</strong> Pembayaran Anda telah berhasil diverifikasi dan akun Anda telah diaktifkan kembali.
      </div>
      
      <h3>📋 Detail Pembayaran:</h3>
      <table class="info-table">
        <tr>
          <td>Invoice Number</td>
          <td>{{invoiceNumber}}</td>
        </tr>
        <tr>
          <td>Jumlah</td>
          <td><strong>{{amount}}</strong></td>
        </tr>
        <tr>
          <td>Masa Aktif</td>
          <td>Hingga {{expiredDate}}</td>
        </tr>
      </table>
      
      <p>Akun Anda sekarang aktif dan dapat digunakan untuk mengakses layanan internet.</p>
      
      <p>Terima kasih telah mempercayai layanan kami! 🙏</p>
      
      <div class="footer">
        <p><strong>{{companyName}}</strong></p>
        <p>📞 {{companyPhone}}</p>
      </div>
    </div>
  </div>
</body>
</html>',
  TRUE,
  NOW(),
  NOW()
),
(
  REPLACE(UUID(), '-', ''),
  'Manual Payment Rejection',
  'manual-payment-rejection',
  '❌ Pembayaran Invoice {{invoiceNumber}} Ditolak',
  '<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #f85032 0%, #e73827 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .warning-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 5px; }
    .reason-box { background: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 20px 0; border-radius: 5px; }
    .btn { display: inline-block; background: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
    .footer { text-align: center; margin-top: 30px; padding: 20px; color: #666; font-size: 14px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>❌ Pembayaran Ditolak</h1>
    </div>
    <div class="content">
      <p>Halo <strong>{{customerName}}</strong>,</p>
      
      <div class="warning-box">
        Mohon maaf, bukti pembayaran Anda untuk invoice <strong>{{invoiceNumber}}</strong> tidak dapat diverifikasi.
      </div>
      
      <h3>📋 Alasan Penolakan:</h3>
      <div class="reason-box">
        {{rejectionReason}}
      </div>
      
      <h3>🔄 Langkah Selanjutnya:</h3>
      <p>Silakan upload ulang bukti transfer yang valid melalui tombol di bawah ini:</p>
      
      <p style="text-align: center;">
        <a href="{{paymentLink}}" class="btn">Upload Ulang Bukti Transfer</a>
      </p>
      
      <h4>✅ Pastikan:</h4>
      <ul>
        <li>Foto bukti transfer jelas dan terbaca</li>
        <li>Jumlah transfer sesuai dengan tagihan</li>
        <li>Tanggal transfer tercantum</li>
      </ul>
      
      <div class="footer">
        <p><strong>{{companyName}}</strong></p>
        <p>📞 {{companyPhone}}</p>
      </div>
    </div>
  </div>
</body>
</html>',
  TRUE,
  NOW(),
  NOW()
),
(
  REPLACE(UUID(), '-', ''),
  'Maintenance Outage',
  'maintenance-outage',
  '⚠️ Pemberitahuan Gangguan - {{issueType}}',
  '<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .alert-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 5px; }
    .info-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    .info-table td { padding: 10px; border-bottom: 1px solid #ddd; }
    .info-table td:first-child { font-weight: bold; width: 40%; }
    .footer { text-align: center; margin-top: 30px; padding: 20px; color: #666; font-size: 14px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>⚠️ Informasi Gangguan Jaringan</h1>
    </div>
    <div class="content">
      <p>Halo <strong>{{customerName}}</strong>,</p>
      
      <div class="alert-box">
        Kami informasikan bahwa saat ini terjadi gangguan pada jaringan internet kami.
      </div>
      
      <h3>📋 Detail Gangguan:</h3>
      <table class="info-table">
        <tr>
          <td>🔧 Jenis Gangguan</td>
          <td><strong>{{issueType}}</strong></td>
        </tr>
        <tr>
          <td>📍 Area Terdampak</td>
          <td>{{affectedArea}}</td>
        </tr>
        <tr>
          <td>📝 Keterangan</td>
          <td>{{description}}</td>
        </tr>
        <tr>
          <td>⏰ Estimasi Pemulihan</td>
          <td><strong>{{estimatedTime}}</strong></td>
        </tr>
        <tr>
          <td>🔄 Status</td>
          <td>Sedang dalam perbaikan</td>
        </tr>
      </table>
      
      <p>Tim teknis kami sedang bekerja untuk mengatasi gangguan ini secepat mungkin. Kami mohon maaf atas ketidaknyamanan yang ditimbulkan.</p>
      
      <p><strong>📌 Update:</strong> Kami akan menginformasikan kembali jika layanan sudah pulih normal.</p>
      
      <div class="footer">
        <p><strong>{{companyName}}</strong></p>
        <p>📞 {{companyPhone}}</p>
        <p>Terima kasih atas pengertian Anda 🙏</p>
      </div>
    </div>
  </div>
</body>
</html>',
  TRUE,
  NOW(),
  NOW()
);

-- Success message
SELECT 'Migration completed successfully!' AS status;
SELECT 'Please run: npm install && npm run db:push' AS next_step;
