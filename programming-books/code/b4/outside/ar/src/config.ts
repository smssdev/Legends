// كل مفتاح وسر يأتي من البيئة؛ ولا شيء منها في الكود
const need = (name: string) => {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not set`);
  return value;
};

export const config = {
  databaseUrl: need("DATABASE_URL"),
  providerUrl: need("PROVIDER_URL"),
  providerKey: need("PROVIDER_KEY"),
  webhookSecret: need("WEBHOOK_SECRET"),
  smtpUrl: need("SMTP_URL"),
  s3: {
    endpoint: need("S3_ENDPOINT"),
    bucket: need("S3_BUCKET"),
    key: need("S3_KEY"),
    secret: need("S3_SECRET"),
  },
};
