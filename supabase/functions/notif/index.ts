import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

import serviceAccount from '../service-account.json' assert { type: 'json' };

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// ── Ganti google-auth-library (gagal diimport dari CDN) dengan ──────────
// implementasi manual pakai Web Crypto API yang built-in di Deno.
// Ini menggantikan fungsi jwtClient.authorize() sebelumnya.

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const base64url = (input: string) =>
    btoa(input).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');

  const unsignedToken = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claimSet))}`;

  const pem = serviceAccount.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const binaryKey = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsignedToken),
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=+$/, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const jwt = `${unsignedToken}.${encodedSignature}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenJson = await tokenRes.json();
  if (!tokenJson.access_token) {
    throw new Error(`Gagal ambil access token: ${JSON.stringify(tokenJson)}`);
  }
  return tokenJson.access_token;
}

serve(async (req) => {
  try {
    const { data: tugasTelat, error: errTugas } = await supabase
      .from('tugas')
      .select('id, judul, mata_kuliah, user_id, tenggat, notified')
      .eq('selesai', false)
      .eq('notified', false)
      .lte('tenggat', new Date().toISOString());

    if (errTugas) throw errTugas;

    if (!tugasTelat || tugasTelat.length === 0) {
      return new Response(JSON.stringify({ message: 'Tidak ada tugas baru yang lewat deadline.' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    const accessToken = await getAccessToken();
    let sentCount = 0;

    for (const tugas of tugasTelat) {
      const { data: devices, error: errDevice } = await supabase
        .from('device')
        .select('fcm_token')
        .eq('user_id', tugas.user_id);

      if (errDevice || !devices || devices.length === 0) continue;

      const fcmToken = devices[0].fcm_token;

      const fcmPayload = {
        message: {
          token: fcmToken,
          notification: {
            title: '⚠️ Tugas Terlambat!',
            body: `Tugas ${tugas.judul} (${tugas.mata_kuliah}) sudah lewat deadline. Segera kerjakan!`,
          },
        },
      };

      const resp = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(fcmPayload),
      });

      if (resp.ok) {
        await supabase
          .from('tugas')
          .update({ notified: true })
          .eq('id', tugas.id);
        sentCount++;
      } else {
        console.error(`FCM failed for tugas ${tugas.id}:`, await resp.text());
      }
    }

    return new Response(
      JSON.stringify({ message: `Berhasil kirim notif ke ${sentCount} tugas.` }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
})