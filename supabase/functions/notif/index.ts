import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'https://cdn.jsdelivr.net/npm/google-auth-library@9.0.0/build/src/index.js';

import serviceAccount from '../service-account.json' assert { type: 'json' };

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function getAccessToken() {
  const jwtClient = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const tokens = await jwtClient.authorize();
  return tokens.access_token;
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
        // BUG FIX: Patch notified=true per tugas, bukan di luar loop
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