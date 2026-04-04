-- Template untuk Pemberitahuan Perbaikan Selesai

-- Email Template - Maintenance Resolved
INSERT INTO email_templates (id, name, type, subject, htmlBody, isActive, createdAt, updatedAt)
VALUES (
  'maintenance-resolved-001',
  'Perbaikan Selesai',
  'maintenance-resolved',
  '✅ Perbaikan Selesai - Layanan Kembali Normal - {{companyName}}',
  '<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Perbaikan Selesai</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f0fdf4;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f0fdf4; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #10b981; padding: 30px 40px; text-align: center;">
              <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: bold;">✅ Perbaikan Selesai</h1>
              <p style="margin: 10px 0 0; color: #d1fae5; font-size: 16px;">Layanan Internet Kembali Normal</p>
            </td>
          </tr>

          <!-- Status Badge -->
          <tr>
            <td style="padding: 20px 40px 10px; text-align: center;">
              <div style="display: inline-block; padding: 10px 20px; background-color: #d1fae5; color: #065f46; border-radius: 25px; font-size: 15px; font-weight: 700;">
                🎉 LAYANAN AKTIF
              </div>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding: 10px 40px 30px;">
              <p style="margin: 0 0 20px; color: #374151; font-size: 16px; line-height: 1.6;">
                Yth. <strong>{{customerName}}</strong>,
              </p>
              
              <p style="margin: 0 0 20px; color: #374151; font-size: 16px; line-height: 1.6;">
                Kabar baik! Kami dengan senang hati mengabarkan bahwa perbaikan telah selesai dilakukan dan layanan internet Anda sudah kembali normal.
              </p>

              <!-- Success Box -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #d1fae5; border-left: 4px solid #10b981; margin: 20px 0; border-radius: 4px;">
                <tr>
                  <td style="padding: 25px;">
                    <p style="margin: 0 0 15px; color: #065f46; font-size: 18px; font-weight: bold;">
                      ✨ Status Layanan: NORMAL
                    </p>
                    <p style="margin: 0; color: #047857; font-size: 15px; line-height: 1.6;">
                      Layanan internet Anda telah pulih dan berfungsi dengan baik. Anda dapat kembali menikmati koneksi internet seperti biasa.
                    </p>
                  </td>
                </tr>
              </table>

              <p style="margin: 20px 0; color: #374151; font-size: 16px; line-height: 1.6;">
                <strong>Informasi:</strong><br>
                {{description}}
              </p>

              <div style="background-color: #f0fdf4; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 0 0 10px; color: #065f46; font-size: 15px; font-weight: 600;">
                  💡 Tips untuk Anda:
                </p>
                <ul style="margin: 0; padding-left: 20px; color: #047857; font-size: 14px; line-height: 1.8;">
                  <li>Restart perangkat Anda jika koneksi belum stabil</li>
                  <li>Lepas dan pasang kembali kabel jika menggunakan kabel LAN</li>
                  <li>Hubungi kami jika masih mengalami kendala</li>
                </ul>
              </div>

              <p style="margin: 20px 0; color: #374151; font-size: 16px; line-height: 1.6;">
                Terima kasih atas kesabaran dan pengertian Anda selama proses perbaikan. Kami berkomitmen untuk terus memberikan layanan terbaik.
              </p>

              <table width="100%" cellpadding="0" cellspacing="0" style="margin: 20px 0;">
                <tr>
                  <td style="padding: 15px; background-color: #ecfdf5; border-radius: 8px;">
                    <p style="margin: 0 0 10px; color: #065f46; font-size: 15px; font-weight: 600;">
                      📞 Butuh Bantuan?
                    </p>
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td style="padding: 5px 0; color: #047857; font-size: 14px;">
                          <strong>Telepon:</strong> {{companyPhone}}
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 5px 0; color: #047857; font-size: 14px;">
                          <strong>Email:</strong> {{companyEmail}}
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 5px 0; color: #047857; font-size: 14px;">
                          <strong>Website:</strong> {{baseUrl}}
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #ecfdf5; padding: 30px 40px; text-align: center; border-top: 1px solid #d1fae5;">
              <p style="margin: 0 0 10px; color: #047857; font-size: 14px; font-weight: 600;">
                🌟 Terima kasih telah mempercayai layanan kami
              </p>
              <p style="margin: 0; color: #6ee7b7; font-size: 12px;">
                © {{companyName}} - Layanan Internet Terpercaya
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>',
  1,
  NOW(),
  NOW()
)
ON DUPLICATE KEY UPDATE
  subject = VALUES(subject),
  htmlBody = VALUES(htmlBody),
  updatedAt = NOW();

-- WhatsApp Template - Maintenance Resolved
INSERT INTO whatsapp_templates (id, name, type, message, isActive, createdAt, updatedAt)
VALUES (
  'maintenance-resolved-wa-001',
  'Perbaikan Selesai',
  'maintenance-resolved',
  '✅ *PERBAIKAN SELESAI*
🎉 *Layanan Kembali Normal*
━━━━━━━━━━━━━━━━━━━━

Yth. *{{customerName}}* (ID: {{customerId}})

Kabar baik! 🌟

Kami dengan senang hati mengabarkan bahwa *perbaikan telah selesai* dilakukan dan layanan internet Anda sudah *kembali normal*.

✨ *Status:* LAYANAN AKTIF
📡 *Koneksi:* NORMAL

━━━━━━━━━━━━━━━━━━━━
📝 *Informasi:*
{{description}}

━━━━━━━━━━━━━━━━━━━━
💡 *Tips untuk Anda:*
▪️ Restart perangkat jika koneksi belum stabil
▪️ Lepas & pasang kembali kabel LAN jika perlu
▪️ Hubungi kami jika masih ada kendala

Terima kasih atas kesabaran dan pengertian Anda selama proses perbaikan. Kami berkomitmen memberikan layanan terbaik! 🙏

━━━━━━━━━━━━━━━━━━━━
📞 *Butuh Bantuan?*
📱 {{companyPhone}}
✉️ {{companyEmail}}
🌐 {{baseUrl}}

Selamat menikmati layanan internet Anda! 🚀

_{{companyName}}_
_Layanan Internet Terpercaya_ ✨',
  1,
  NOW(),
  NOW()
)
ON DUPLICATE KEY UPDATE
  message = VALUES(message),
  updatedAt = NOW();
