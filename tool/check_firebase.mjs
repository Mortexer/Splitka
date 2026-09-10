import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const config = JSON.parse(await readFile('android/app/google-services.json', 'utf8'));
const project = config.project_info.project_id;
assert.equal(project, 'splitka-18560');
const client = config.client.find(
  (entry) => entry.client_info.android_client_info.package_name === 'pl.splitka.splitka_flutter',
);
assert.ok(client, 'Missing Splitka Android registration');
const apiKey = client.api_key[0].current_key;

async function authRequest(method, body) {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${method}?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15000),
    },
  );
  const data = await response.json();
  if (!response.ok) throw new Error(`Auth ${method}: ${data.error?.message ?? response.status}`);
  return data;
}

// This check creates one temporary anonymous user and removes that same user.
// Tokens stay in memory; no receipts or settings are changed.
const session = await authRequest('signUp', { returnSecureToken: true });
try {
  const claims = JSON.parse(Buffer.from(session.idToken.split('.')[1], 'base64url'));
  assert.equal(claims.aud, project);
  assert.equal(claims.firebase.sign_in_provider, 'anonymous');
  console.log(`PASS: anonymous sign-in works for ${project}.`);
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/households/stancja`,
    {
      headers: { Authorization: `Bearer ${session.idToken}` },
      signal: AbortSignal.timeout(15000),
    },
  );
  const data = await response.json();
  assert.equal(response.status, 403, `Expected denied outsider access, got ${response.status}`);
  assert.equal(data.error?.status, 'PERMISSION_DENIED');
  console.log('PASS: an anonymous outsider cannot read household data.');
} finally {
  await authRequest('delete', { idToken: session.idToken });
  console.log('Removed the temporary diagnostic user.');
}
