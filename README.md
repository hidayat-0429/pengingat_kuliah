# Pengingat Kuliah (Premium Version)

Aplikasi manajemen tugas dan deadline perkuliahan dengan desain premium (Dark Glassmorphism).

## 🔥 Fitur Unggulan
- **Premium UI**: Desain modern menggunakan Dark Glassmorphism, animasi mulus, dan feedback haptic.
- **Manajemen Tugas**: Tambah, edit, dan tandai tugas selesai.
- **Smart Filter**: Filter tugas berdasarkan status (Aktif, Selesai, Terlambat).
- **Notifikasi Multi-Layer**: Notifikasi lokal (alarm) & push notification (FCM via Supabase Edge Function).
- **Aman**: Kredensial tidak lagi di-hardcode (menggunakan `.env`).

## 🛠️ Persiapan

### 1. Environment Variables
Buat file `.env` di root project dan isi dengan kunci Supabase Anda:
```env
SUPABASE_URL=https://[PROJECT_ID].supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI...
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Keamanan Kredensial (PENTING!)
Terdeteksi bahwa kredensial Firebase (`service-account.json`) dan Supabase sempat masuk ke dalam *git history*. **Sangat disarankan** bagi Anda untuk:
1. **Membuat *private key* baru** di Firebase Console (Project Settings -> Service Accounts -> Generate new private key).
2. Memperbarui `service-account.json` di dalam Supabase Edge Function.
3. Mencabut (revoke) kunci lama dari Firebase.

## 🚀 Menjalankan Aplikasi
```bash
flutter run
```

## 🌩️ Deploy Edge Function
Pastikan sudah menginstal Supabase CLI.
```bash
cd supabase
supabase functions deploy notif --no-verify-jwt
```
Set secrets untuk Edge Function:
```bash
supabase secrets set SUPABASE_URL=https://[PROJECT_ID].supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJhbG...
```
