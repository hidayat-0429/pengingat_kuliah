import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

// 🔥 CONVERT PEM → ARRAY BUFFER (FIX ASN.1 ERROR)
function pemToArrayBuffer(pem: string) {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  const binary = atob(base64);
  const buffer = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i++) {
    buffer[i] = binary.charCodeAt(i);
  }

  return buffer.buffer;
}

// 🔥 GET ACCESS TOKEN (FCM V1)
async function getAccessToken() {
  const b64 = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64")!;
  const sa = JSON.parse(atob(b64));

  const now = Math.floor(Date.now() / 1000);

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  function base64url(obj: any) {
    return btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
  }

  const unsigned = `${base64url(header)}.${base64url(payload)}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned)
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt = `${unsigned}.${sig}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();

  if (!data.access_token) {
    throw new Error(JSON.stringify(data));
  }

  return data.access_token;
}

// 🔥 MAIN FUNCTION
serve(async () => {
  try {
    const url = "https://kwvmkciknxkxzqkchzra.supabase.co";
    const key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3dm1rY2lrbnhreHpxa2NoenJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NzE2MjQsImV4cCI6MjA5MjU0NzYyNH0.sRkWvne-zkRqgtufLj8KLG82ciCGMGLE3vp0WkOAiwQ"; // 🔥 GANTI INI
    const projectId = "pengingatkuliah";

    const token = await getAccessToken();

    const now = new Date(Date.now() + 7 * 60 * 60 * 1000).toISOString();
    // ambil tugas yang sudah lewat
    const tugasRes = await fetch(
  `${url}/rest/v1/tugas?tenggat=lte.${now}&selesai=eq.false&notified=eq.false`,
  {
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
    },
  }
);

    const tugasData = await tugasRes.json();
const tugas = Array.isArray(tugasData) ? tugasData : [];

    // ambil semua device
    const deviceRes = await fetch(`${url}/rest/v1/device`, {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
      },
    });

    const deviceData = await deviceRes.json();
const devices = Array.isArray(deviceData) ? deviceData : [];

    // kirim notif
    for (const t of tugas) {
      for (const d of devices) {
        await fetch(
          `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${token}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token: d.fcm_token,
                notification: {
                  title: "Deadline Tugas",
                  body: `${t.judul} (${t.mata_kuliah})`,
                },
              },
            }),
          }
        );
      }
    }
await fetch(`${url}/rest/v1/tugas?id=eq.${t.id}`, {
  method: "PATCH",
  headers: {
    apikey: key,
    Authorization: `Bearer ${key}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    notified: true,
  }),
});
    return new Response(JSON.stringify({ tugas, devices }));
  } catch (e) {
    return new Response("ERROR: " + e.message);
  }
});