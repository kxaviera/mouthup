import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { readFileSync, unlinkSync } from 'fs';
import { extname } from 'path';

@Injectable()
export class S3StorageService {
  private readonly logger = new Logger(S3StorageService.name);
  private client: S3Client | null = null;

  constructor(private readonly config: ConfigService) {}

  isConfigured(): boolean {
    return !!(
      this.config.get('S3_BUCKET') &&
      this.config.get('S3_ACCESS_KEY') &&
      this.config.get('S3_SECRET_KEY')
    );
  }

  private getClient(): S3Client {
    if (!this.client) {
      const endpoint = this.config.get('S3_ENDPOINT');
      this.client = new S3Client({
        region: this.config.get('S3_REGION', 'auto'),
        endpoint: endpoint || undefined,
        forcePathStyle: !!endpoint,
        credentials: {
          accessKeyId: this.config.getOrThrow('S3_ACCESS_KEY'),
          secretAccessKey: this.config.getOrThrow('S3_SECRET_KEY'),
        },
      });
    }
    return this.client;
  }

  publicUrl(key: string): string {
    const base = this.config.get('S3_PUBLIC_URL');
    if (base) return `${base.replace(/\/$/, '')}/${key}`;
    const bucket = this.config.getOrThrow('S3_BUCKET');
    const endpoint = this.config.get('S3_ENDPOINT');
    if (endpoint) return `${endpoint.replace(/\/$/, '')}/${bucket}/${key}`;
    const region = this.config.get('S3_REGION', 'us-east-1');
    return `https://${bucket}.s3.${region}.amazonaws.com/${key}`;
  }

  async uploadLocalFile(localPath: string, key: string, contentType: string): Promise<string> {
    const body = readFileSync(localPath);
    await this.getClient().send(
      new PutObjectCommand({
        Bucket: this.config.getOrThrow('S3_BUCKET'),
        Key: key,
        Body: body,
        ContentType: contentType,
      }),
    );
    try {
      unlinkSync(localPath);
    } catch {
      this.logger.warn(`Could not delete temp file ${localPath}`);
    }
    return this.publicUrl(key);
  }

  contentTypeForExt(ext: string): string {
    const map: Record<string, string> = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.gif': 'image/gif',
      '.mp4': 'video/mp4',
      '.webm': 'video/webm',
      '.mov': 'video/quicktime',
    };
    return map[ext.toLowerCase()] ?? 'application/octet-stream';
  }
}
