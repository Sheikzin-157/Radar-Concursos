import { createSign } from 'node:crypto';

interface FcmCredentials {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

function encode(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

/** Server-only OAuth2 service-account exchange. Never ship credentials to Flutter. */
export async function getFcmAccessToken(
  credentials: FcmCredentials,
  fetcher: typeof fetch = fetch,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = encode({ alg: 'RS256', typ: 'JWT' });
  const payload = encode({
    iss: credentials.clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  });
  const unsignedJwt = `${header}.${payload}`;
  const signer = createSign('RSA-SHA256');
  signer.update(unsignedJwt);
  signer.end();
  const signature = signer.sign(credentials.privateKey).toString('base64url');
  const assertion = `${unsignedJwt}.${signature}`;

  const response = await fetcher('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
    signal: AbortSignal.timeout(10000),
  });

  if (!response.ok) throw new Error('FCM OAuth authorization failed');
  const body: unknown = await response.json();
  if (!body || typeof body !== 'object' || !('access_token' in body) ||
      typeof body.access_token !== 'string') {
    throw new Error('FCM OAuth response has no access token');
  }
  return body.access_token;
}

export async function sendFcmNotification(args: {
  credentials: FcmCredentials;
  token: string;
  title: string;
  body: string;
  competitionId: string;
  accessToken: string;
  fetcher?: typeof fetch;
}): Promise<void> {
  const response = await (args.fetcher ?? fetch)(
    `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(args.credentials.projectId)}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${args.accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: args.token,
          notification: { title: args.title, body: args.body },
          data: { competitionId: args.competitionId },
        },
      }),
      signal: AbortSignal.timeout(10000),
    },
  );
  if (!response.ok) {
    throw new Error(`FCM delivery rejected (HTTP ${response.status})`);
  }
}

export function readFcmCredentials(): FcmCredentials | null {
  const projectId = process.env.FCM_PROJECT_ID;
  const clientEmail = process.env.FCM_CLIENT_EMAIL;
  const privateKey = process.env.FCM_PRIVATE_KEY?.replace(/\\n/g, '\n');
  if (!projectId || !clientEmail || !privateKey) return null;
  return { projectId, clientEmail, privateKey };
}
