module.exports = {
  apps: [
    {
      name: 'mouthup-api',
      cwd: './mouthup-api',
      script: 'dist/main.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
      },
      max_memory_restart: '768M',
      error_file: './logs/api-error.log',
      out_file: './logs/api-out.log',
      merge_logs: true,
      autorestart: true,
      watch: false,
    },
    {
      name: 'mouthup-admin',
      cwd: './mouthup-admin',
      script: 'node_modules/next/dist/bin/next',
      args: 'start -p 3001',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: '3001',
      },
      max_memory_restart: '512M',
      error_file: './logs/admin-error.log',
      out_file: './logs/admin-out.log',
      merge_logs: true,
      autorestart: true,
      watch: false,
    },
  ],
};
