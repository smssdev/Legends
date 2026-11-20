import { randomUUID } from "node:crypto";
import {
  DeleteObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { config } from "./config.ts";
import { pool } from "./db.ts";

const s3 = new S3Client({
  endpoint: config.s3.endpoint,
  region: "us-east-1",
  forcePathStyle: true,
  credentials: { accessKeyId: config.s3.key, secretAccessKey: config.s3.secret },
});
const TYPES = {
  "image/png": "png",
  "image/jpeg": "jpg",
  "image/webp": "webp",
} as const;
const MAX = 1024 * 1024;
type Type = keyof typeof TYPES;
export const isType = (t: string): t is Type => t in TYPES;

// the browser uploads straight to storage; the server only signs a short-lived URL
export async function logoUploadUrl(businessId: number, type: Type, size: number) {
  if (size > MAX) return { error: "too-big" as const };
  // the key is chosen by the server: the client cannot write anywhere else
  const key = `logos/${businessId}/${randomUUID()}.${TYPES[type]}`;
  const command = new PutObjectCommand({
    Bucket: config.s3.bucket,
    Key: key,
    ContentType: type,
  });
  const url = await getSignedUrl(s3, command, { expiresIn: 300 });
  return { key, url };
}

// trust, then verify: check what was really stored before using it
export async function acceptLogo(businessId: number, key: string) {
  if (!key.startsWith(`logos/${businessId}/`)) return "not-found";
  const head = await s3
    .send(new HeadObjectCommand({ Bucket: config.s3.bucket, Key: key }))
    .catch(() => null);
  if (!head) return "not-found";
  if ((head.ContentLength ?? 0) > MAX || !isType(head.ContentType ?? "")) {
    await s3.send(new DeleteObjectCommand({ Bucket: config.s3.bucket, Key: key }));
    return (head.ContentLength ?? 0) > MAX ? "too-big" : "bad-type";
  }
  await pool.query("UPDATE businesses SET logo_key = $1 WHERE id = $2", [
    key,
    businessId,
  ]);
  return "ok";
}
