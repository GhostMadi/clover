/// Shared Cloudflare R2 (S3-compatible) helpers for Edge Functions.
/// Secrets: R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_ENDPOINT, R2_BUCKET_NAME, R2_PUBLIC_URL
///
/// <reference path="../deno.d.ts" />
import {
  DeleteObjectsCommand,
  PutObjectCommand,
  S3Client,
} from "npm:@aws-sdk/client-s3@3.787.0";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner@3.787.0";

export type R2Env = {
  accessKeyId: string;
  secretAccessKey: string;
  endpoint: string;
  bucket: string;
  publicBase: string;
};

export function requireR2Env(): R2Env {
  const accessKeyId = Deno.env.get("R2_ACCESS_KEY_ID")?.trim() ?? "";
  const secretAccessKey = Deno.env.get("R2_SECRET_ACCESS_KEY")?.trim() ?? "";
  const endpoint = Deno.env.get("R2_ENDPOINT")?.trim() ?? "";
  const bucket = Deno.env.get("R2_BUCKET_NAME")?.trim() ?? "";
  const publicBase = (Deno.env.get("R2_PUBLIC_URL")?.trim() ?? "").replace(/\/+$/, "");
  if (!accessKeyId || !secretAccessKey || !endpoint || !bucket || !publicBase) {
    throw new Error("Missing R2 env (ACCESS_KEY_ID / SECRET / ENDPOINT / BUCKET_NAME / PUBLIC_URL)");
  }
  return { accessKeyId, secretAccessKey, endpoint, bucket, publicBase };
}

export function createR2Client(env: R2Env = requireR2Env()): S3Client {
  return new S3Client({
    region: "auto",
    endpoint: env.endpoint,
    credentials: {
      accessKeyId: env.accessKeyId,
      secretAccessKey: env.secretAccessKey,
    },
    forcePathStyle: true,
    // AWS SDK ≥3.729 defaults to CRC32 checksums; R2 rejects / browser PUT breaks.
    requestChecksumCalculation: "WHEN_REQUIRED",
    responseChecksumValidation: "WHEN_REQUIRED",
  });
}

export async function createPresignedPutUrl(opts: {
  fileKey: string;
  contentType: string;
  expiresInSeconds?: number;
  env?: R2Env;
}): Promise<{ uploadUrl: string; publicUrl: string; fileKey: string }> {
  const env = opts.env ?? requireR2Env();
  const s3 = createR2Client(env);
  const command = new PutObjectCommand({
    Bucket: env.bucket,
    Key: opts.fileKey,
    ContentType: opts.contentType,
  });
  const uploadUrl = await getSignedUrl(s3, command, {
    expiresIn: opts.expiresInSeconds ?? 15 * 60,
    // Keep checksum headers out of the signed URL — browser only sends Content-Type.
    unhoistableHeaders: new Set([
      "x-amz-checksum-crc32",
      "x-amz-checksum-crc32c",
      "x-amz-checksum-sha1",
      "x-amz-checksum-sha256",
      "x-amz-sdk-checksum-algorithm",
      "x-amz-checksum-mode",
    ]),
  });
  return {
    uploadUrl,
    publicUrl: `${env.publicBase}/${opts.fileKey}`,
    fileKey: opts.fileKey,
  };
}

/** Strip query/hash; if URL is under R2_PUBLIC_URL, return object key. */
export function fileKeyFromPublicUrl(url: string, env: R2Env = requireR2Env()): string | null {
  const raw = url.trim().split("#")[0]?.split("?")[0] ?? "";
  if (!raw) return null;
  const base = env.publicBase;
  if (raw === base) return null;
  if (raw.startsWith(`${base}/`)) {
    const key = decodeURIComponent(raw.slice(base.length + 1)).replace(/^\/+/, "");
    return key.length > 0 ? key : null;
  }
  return null;
}

export async function deleteR2Keys(fileKeys: string[], env: R2Env = requireR2Env()): Promise<number> {
  const unique = [...new Set(fileKeys.map((k) => k.trim()).filter(Boolean))];
  if (unique.length === 0) return 0;

  const s3 = createR2Client(env);
  let deleted = 0;
  // S3 DeleteObjects max 1000 per call
  for (let i = 0; i < unique.length; i += 1000) {
    const chunk = unique.slice(i, i + 1000);
    const out = await s3.send(
      new DeleteObjectsCommand({
        Bucket: env.bucket,
        Delete: {
          Objects: chunk.map((Key) => ({ Key })),
          Quiet: true,
        },
      }),
    );
    deleted += chunk.length - (out.Errors?.length ?? 0);
  }
  return deleted;
}
