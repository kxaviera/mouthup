import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);

  constructor(private readonly config: ConfigService) {}

  isConfigured(): boolean {
    return !!this.config.get('RESEND_API_KEY');
  }

  async sendVerificationCode(email: string, code: string, purpose: 'verify' | 'reset') {
    const subject =
      purpose === 'verify' ? 'Verify your MouthUp email' : 'Reset your MouthUp password';
    const body =
      purpose === 'verify'
        ? `<p>Your MouthUp verification code is: <strong>${code}</strong></p><p>Expires in 15 minutes.</p>`
        : `<p>Your MouthUp password reset code is: <strong>${code}</strong></p><p>Expires in 15 minutes.</p>`;

    return this.send(email, subject, body);
  }

  private async send(to: string, subject: string, html: string): Promise<boolean> {
    const apiKey = this.config.get('RESEND_API_KEY');
    const from = this.config.get('EMAIL_FROM', 'MouthUp <noreply@mouthup.app>');
    if (!apiKey) {
      this.logger.warn(`Email not sent (RESEND_API_KEY unset): ${subject} → ${to}`);
      return false;
    }

    try {
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ from, to, subject, html }),
      });
      if (!res.ok) {
        const err = await res.text();
        this.logger.error(`Resend failed: ${err}`);
        return false;
      }
      return true;
    } catch (err) {
      this.logger.error(`Email send error: ${err instanceof Error ? err.message : err}`);
      return false;
    }
  }
}
