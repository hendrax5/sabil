-- Update atau Insert template maintenance-outage dengan variabel {{status}}

-- Email Template
INSERT INTO email_templates (id, name, type, subject, htmlBody, isActive, createdAt, updatedAt)
VALUES (
  'maintenance-outage-001',
  'maintenance-outage',
  'maintenance-outage',
  '⚠️ Pemberitahuan Gangguan - {{companyName}}',
  '<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pemberitahuan Gangguan</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f3f4f6;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f3f4f6; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #ef4444; padding: 30px 40px; text-align: center;">
              <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: bold;">⚠️ Pemberitahuan Gangguan</h1>
            </td>
          </tr>

          <!-- Status Badge -->
          <tr>
            <td style="padding: 20px 40px 10px; text-align: center;">
              <div style="display: inline-block; padding: 8px 16px; background-color: #fee2e2; color: #991b1b; border-radius: 20px; font-size: 14px; font-weight: 600;">
                {{status}}
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
                Kami ingin menginformasikan bahwa saat ini terjadi gangguan pada layanan internet Anda.
              </p>

              <!-- Info Box -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #fef2f2; border-left: 4px solid #ef4444; margin: 20px 0;">
                <tr>
                  <td style="padding: 20px;">
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td style="padding: 8px 0; color: #7f1d1d; font-size: 14px;">
                          <strong>Jenis Gangguan:</strong>
                        </td>
                        <td style="padding: 8px 0; color: #991b1b; font-size: 14px;">
                          {{issueType}}
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 8px 0; color: #7f1d1d; font-size: 14px;">
                          <strong>Area Terdampak:</strong>
                        </td>
                        <td style="padding: 8px 0; color: #991b1b; font-size: 14px;">
                          {{affectedArea}}
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 8px 0; color: #7f1d1d; font-size: 14px;">
                          <strong>Estimasi Waktu:</strong>
                        </td>
                        <td style="padding: 8px 0; color: #991b1b; font-size: 14px;">
                          {{estimatedTime}}
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <p style="margin: 20px 0; color: #374151; font-size: 16px; line-height: 1.6;">
                <strong>Detail:</strong><br>
                {{description}}
              </p>

              <p style="margin: 20px 0; color: #374151; font-size: 16px; line-height: 1.6;">
                Kami mohon maaf atas ketidaknyamanan yang ditimbulkan dan berupaya semaksimal mungkin untuk menyelesaikan masalah ini sesegera mungkin.
              </p>

              <p style="margin: 20px 0; color: #374151; font-size: 16px; line-height: 1.6;">
                Jika Anda memiliki pertanyaan, silakan hubungi kami di:
              </p>

              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding: 8px 0; color: #6b7280; font-size: 14px;">
                    📞 <strong>Telepon:</strong> {{companyPhone}}
                  </td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; color: #6b7280; font-size: 14px;">
                    ✉️ <strong>Email:</strong> {{companyEmail}}
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #f9fafb; padding: 30px 40px; text-align: center; border-top: 1px solid #e5e7eb;">
              <p style="margin: 0 0 10px; color: #6b7280; font-size: 14px;">
                Terima kasih atas pengertian Anda
              </p>
              <p style="margin: 0; color: #9ca3af; font-size: 12px;">
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

-- WhatsApp Template
INSERT INTO whatsapp_templates (id, name, type, message, isActive, createdAt, updatedAt)
VALUES (
  'maintenance-outage-wa-001',
  'maintenance-outage',
  'maintenance-outage',
  '⚠️ *PEMBERITAHUAN GANGGUAN*
━━━━━━━━━━━━━━━━━━━━

Yth. *{{customerName}}* (ID: {{customerId}})

Kami ingin menginformasikan bahwa saat ini terjadi gangguan pada layanan internet Anda.

📊 *Status:* {{status}}

📋 *Detail Gangguan:*
▪️ Jenis: {{issueType}}
▪️ Area: {{affectedArea}}
▪️ Estimasi: {{estimatedTime}}

📝 *Keterangan:*
{{description}}

Kami mohon maaf atas ketidaknyamanan yang ditimbulkan dan sedang berupaya menyelesaikan masalah ini sesegera mungkin.

━━━━━━━━━━━━━━━━━━━━
💬 Hubungi Kami:
📞 {{companyPhone}}
✉️ {{companyEmail}}

Terima kasih atas pengertian Anda.

_{{companyName}}_',
  1,
  NOW(),
  NOW()
)
ON DUPLICATE KEY UPDATE
  message = VALUES(message),
  updatedAt = NOW();
