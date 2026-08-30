import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestExpressApplication } from '@nestjs/platform-express';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const config = app.get(ConfigService);
  const isProd = config.get('NODE_ENV') === 'production';

  if (isProd) {
    app.set('trust proxy', 1);
  }

  app.setGlobalPrefix(config.get('API_PREFIX', 'api/v1'));
  app.useWebSocketAdapter(new IoAdapter(app));

  const devWebOrigins = [
    'http://localhost:57400',
    'http://localhost:57401',
    'http://127.0.0.1:57400',
    'http://127.0.0.1:57401',
    'http://localhost:3001',
    'http://127.0.0.1:3001',
  ];

  const origins = [
    config.get('APP_URL'),
    config.get('ADMIN_URL'),
    ...devWebOrigins,
  ].filter(Boolean) as string[];

  app.enableCors({
    origin: origins,
    credentials: true,
  });

  app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads/' });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const port = config.get<number>('PORT', 3000);
  await app.listen(port);
  console.log(
    `MouthUp API running on port ${port} (${config.get('NODE_ENV', 'development')})`,
  );
}
bootstrap();
