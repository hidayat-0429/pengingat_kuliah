import '../config/app_config.dart';
import '../models/tugas.dart';

class TugasService {
  static final _db = AppConfig.supabase;

  static Future<List<Tugas>> fetchAll() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final response = await _db
        .from('tugas')
        .select()
        .eq('user_id', user.id)
        .order('tenggat', ascending: true);

    return List<Map<String, dynamic>>.from(response)
        .map((e) => Tugas.fromJson(e))
        .toList();
  }

  static Future<void> add({
    required String mataKuliah,
    required String judul,
    required DateTime tenggat,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    await _db.from('tugas').insert({
      'mata_kuliah': mataKuliah,
      'judul': judul,
      'tenggat': tenggat.toIso8601String(),
      'selesai': false,
      'user_id': user.id,
    });
  }

  static Future<void> update(int id, {
    String? mataKuliah,
    String? judul,
    DateTime? tenggat,
  }) async {
    final updates = <String, dynamic>{};
    if (mataKuliah != null) updates['mata_kuliah'] = mataKuliah;
    if (judul != null) updates['judul'] = judul;
    if (tenggat != null) updates['tenggat'] = tenggat.toIso8601String();
    if (updates.isEmpty) return;
    await _db.from('tugas').update(updates).eq('id', id);
  }

  static Future<void> toggleSelesai(int id, bool selesai) async {
    await _db.from('tugas').update({'selesai': selesai}).eq('id', id);
  }

  static Future<void> delete(int id) async {
    await _db.from('tugas').delete().eq('id', id);
  }
}
