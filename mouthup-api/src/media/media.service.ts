import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { extname, join } from 'path';
import { S3StorageService } from '../storage/s3-storage.service';

@Injectable()
export class MediaService {
  constructor(
    private readonly config: ConfigService,
    private readonly s3: S3StorageService,
  ) {}

  async toPublicAsset(file: Express.Multer.File) {
    const ext = extname(file.originalname).toLowerCase();
    const isVideo = ['.mp4', '.webm', '.mov'].includes(ext);

    if (this.s3.isConfigured()) {
      const key = `media/${file.filename}`;
      const url = await this.s3.uploadLocalFile(
        join(process.cwd(), 'uploads', file.filename),
        key,
        this.s3.contentTypeForExt(ext),
      );
      return { type: isVideo ? ('VIDEO' as const) : ('IMAGE' as const), url };
    }

    const base =
      this.config.get('MEDIA_PUBLIC_URL') ??
      `${this.config.get('APP_URL', 'http://localhost:3000')}/uploads`;
    const url = `${base.replace(/\/$/, '')}/${file.filename}`;
    return { type: isVideo ? ('VIDEO' as const) : ('IMAGE' as const), url };
  }
}
