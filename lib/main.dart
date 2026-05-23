import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'profile_page.dart';
import 'splash_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  RemoteNotification? notification = message.notification;

  if (notification != null) {
    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://kwvmkciknxkxzqkchzra.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3dm1rY2lrbnhreHpxa2NoenJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NzE2MjQsImV4cCI6MjA5MjU0NzYyNH0.sRkWvne-zkRqgtufLj8KLG82ciCGMGLE3vp0WkOAiwQ',
  );

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  const settings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(settings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("NOTIF MASUK");

    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id',
            'Reminder',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  runApp(const AplikasiSaya());
}

class AplikasiSaya extends StatelessWidget {
  const AplikasiSaya({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pengingat Tugas',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff4f46e5),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

class Tugas {
  String mataKuliah;
  String judulTugas;
  DateTime tenggat;
  bool selesai;

  Tugas(this.mataKuliah, this.judulTugas, this.tenggat, {this.selesai = false});
}

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  final supabase = Supabase.instance.client;

  List<Tugas> daftarTugas = [];

  String namaUser = '';

  Future<void> initFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();

      print("TOKEN FCM:");
      print(token);

      final user = supabase.auth.currentUser;

      print("USER:");
      print(user?.id);

      if (token == null || user == null) {
        print("TOKEN ATAU USER NULL");
        return;
      }

      final result = await supabase.from('device').upsert({
        'user_id': user.id,
        'fcm_token': token,
      });

      print("BERHASIL SIMPAN TOKEN");
      print(result);
    } catch (e) {
      print("ERROR FCM:");
      print(e);
    }
  }

  Future<void> ambilNamaUser() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final data = await supabase
          .from('profiles')
          .select('nama')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          namaUser = data['nama'] ?? '';
        });
      }
    } catch (e, stackTrace) {
      print("ERROR FCM:");
      print(e);
      print(stackTrace);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ambilData();
      await ambilNamaUser();
      await initFCM();
    });
  }

  Future<void> ambilData() async {
    try {
      final user = supabase.auth.currentUser;

      final response = await supabase
          .from('tugas')
          .select()
          .eq('user_id', user!.id);

      final dataList = List<Map<String, dynamic>>.from(response);

      setState(() {
        daftarTugas = dataList.map((item) {
          return Tugas(
            item['mata_kuliah'],
            item['judul'],
            DateTime.parse(item['tenggat']),
            selesai: item['selesai'] ?? false,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('ERROR: $e');
    }
  }

  Future<void> jadwalkanNotif(Tugas tugas) async {
    final jadwal = tz.TZDateTime(
      tz.local,
      tugas.tenggat.year,
      tugas.tenggat.month,
      tugas.tenggat.day,
      tugas.tenggat.hour,
      tugas.tenggat.minute,
    );

    if (jadwal.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Deadline Tugas',
      '${tugas.judulTugas} (${tugas.mataKuliah})',
      jadwal,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> tambahTugas(
    String mataKuliah,
    String judul,
    DateTime tenggat,
  ) async {
    try {
      final user = supabase.auth.currentUser;

      await supabase.from('tugas').insert({
        'mata_kuliah': mataKuliah,
        'judul': judul,
        'tenggat': tenggat.toIso8601String(),
        'selesai': false,
        'user_id': user!.id,
      });

      final tugasBaru = Tugas(mataKuliah, judul, tenggat);

      await jadwalkanNotif(tugasBaru);

      await ambilData();
    } catch (e) {
      debugPrint('ERROR: $e');
    }
  }

  Future<void> hapusTugas(int index) async {
    try {
      final item = daftarTugas[index];

      await supabase.from('tugas').delete().match({
        'judul': item.judulTugas,
        'mata_kuliah': item.mataKuliah,
      });

      await ambilData();
    } catch (e) {
      debugPrint('ERROR: $e');
    }
  }

  String formatTanggal(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} - '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xfff5f7ff), Color(0xffffffff)],
        ),
      ),

      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 85,
          elevation: 0,
          backgroundColor: Colors.transparent,

          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4f46e5), Color(0xff3730a3)],
              ),
            ),
          ),

          title: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengingat Tugas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                Text(
                  'Halo, $namaUser 👋',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.person, color: Color(0xff4f46e5)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        body: daftarTugas.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_rounded,
                      size: 100,
                      color: Colors.grey.shade400,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Belum Ada Tugas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Tekan tombol + untuk menambahkan tugas',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: daftarTugas.length,
                itemBuilder: (context, index) {
                  final item = daftarTugas[index];

                  final sisaJam = item.tenggat
                      .difference(DateTime.now())
                      .inHours;

                  final mendekati = sisaJam >= 0 && sisaJam <= 24;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xfffcfcff),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),

                      leading: Transform.scale(
                        scale: 1.0,
                        child: Checkbox(
                          value: item.selesai,
                          activeColor: const Color(0xff4f46e5),
                          checkColor: Colors.white,
                          side: const BorderSide(color: Color(0xffcbd5e1)),
                          onChanged: (value) async {
                            setState(() {
                              item.selesai = value!;
                            });

                            await supabase
                                .from('tugas')
                                .update({'selesai': value})
                                .match({
                                  'judul': item.judulTugas,
                                  'mata_kuliah': item.mataKuliah,
                                });
                          },
                        ),
                      ),

                      title: Text(
                        item.judulTugas,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: item.selesai
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.book,
                                  color: Colors.black54,
                                  size: 18,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    item.mataKuliah,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.black54,
                                  size: 18,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  formatTanggal(item.tenggat),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),

                            if (mendekati && !item.selesai)
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xfffff1f2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xffef4444),
                                      size: 16,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Deadline Mendekat',
                                      style: TextStyle(
                                        color: Color(0xffef4444),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final hasil = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Tugas'),
                              content: const Text(
                                'Apakah Anda yakin ingin menghapus tugas ini?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );

                          if (hasil == true) {
                            hapusTugas(index);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),

        floatingActionButton: FloatingActionButton.extended(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: const Color(0xff4f46e5),
          elevation: 8,

          icon: const Icon(Icons.add),

          label: const Text(
            'Tambah',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          onPressed: () async {
            final c1 = TextEditingController();
            final c2 = TextEditingController();

            final tgl = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );

            if (tgl == null) return;

            final jam = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (jam == null) return;

            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.assignment_add, color: Color(0xff4f46e5)),

                          SizedBox(width: 10),

                          Text(
                            'Tambah Tugas',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: c1,
                            decoration: InputDecoration(
                              labelText: 'Mata Kuliah',
                              hintText: 'Masukkan mata kuliah',

                              prefixIcon: const Icon(Icons.book),

                              filled: true,
                              fillColor: Colors.grey.shade100,

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextField(
                            controller: c2,
                            decoration: InputDecoration(
                              labelText: 'Judul Tugas',
                              hintText: 'Masukkan judul tugas',

                              prefixIcon: const Icon(Icons.edit_document),

                              filled: true,
                              fillColor: Colors.grey.shade100,

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (c1.text.isEmpty || c2.text.isEmpty) {
                              return;
                            }

                            final dt = DateTime(
                              tgl.year,
                              tgl.month,
                              tgl.day,
                              jam.hour,
                              jam.minute,
                            );

                            tambahTugas(c1.text, c2.text, dt);

                            Navigator.pop(context);
                          },
                          child: const Text('Simpan'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
