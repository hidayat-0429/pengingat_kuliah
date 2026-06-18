import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/app_config.dart';
import '../models/tugas.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'pengingat_tugas_channel',
      'Pengingat Tugas',
      channelDescription: 'Notifikasi pengingat deadline tugas kuliah',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  static Future<void> initialize() async {
    // Timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final notifGranted = await androidImpl?.requestNotificationsPermission();
    debugPrint('[Notif] Izin notifikasi: $notifGranted');

    // Izin exact alarm terpisah dari izin notifikasi biasa (Android 12+).
    // Tanpa ini, zonedSchedule dengan mode exact akan gagal di beberapa device.
    final exactAlarmGranted = await androidImpl?.requestExactAlarmsPermission();
    debugPrint('[Notif] Izin exact alarm: $exactAlarmGranted');

    // Firebase messaging
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    FirebaseMessaging.onMessage.listen(_foregroundHandler);
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    // FCM otomatis menampilkan notifikasi saat aplikasi di background jika ada objek `notification`.
    // Kita tidak boleh memanggil _plugin.show() di sini karena akan menyebabkan notifikasi ganda (spam).
  }

  static Future<void> _foregroundHandler(RemoteMessage message) async {
    final n = message.notification;
    if (n != null) {
      await _plugin.show(n.hashCode, n.title, n.body, _notifDetails);
    }
  }

  static Future<void> scheduleForTugas(Tugas tugas) async {
    final jadwal = tz.TZDateTime(
      tz.local,
      tugas.tenggat.year,
      tugas.tenggat.month,
      tugas.tenggat.day,
      tugas.tenggat.hour,
      tugas.tenggat.minute,
    );

    final now = tz.TZDateTime.now(tz.local);
    debugPrint('[Notif] Jadwal: $jadwal | Sekarang: $now');

    if (jadwal.isBefore(now)) {
      debugPrint('[Notif] Dibatalkan: tenggat sudah lewat, tidak dijadwalkan.');
      return;
    }

    try {
      await _plugin.zonedSchedule(
        tugas.id,
        'Deadline Tugas ðŸ“š',
        '${tugas.judulTugas} â€” ${tugas.mataKuliah}',
        jadwal,
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[Notif] Berhasil dijadwalkan untuk id=${tugas.id}');
    } catch (e) {
      debugPrint('[Notif] Gagal menjadwalkan: $e');
      rethrow;
    }
  }

  static Future<void> cancelForTugas(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> initFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken();
      final user = AppConfig.supabase.auth.currentUser;
      if (token == null || user == null) return;

      await AppConfig.supabase.from('device').upsert({
        'user_id': user.id,
        'fcm_token': token,
      });
    } catch (_) {
      // FCM registration gagal â€” silent fail
    }
  }
}
