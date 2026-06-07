import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AuthService {
  static SupabaseClient get _db => AppConfig.supabase;

  static User? get currentUser => _db.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<void> login(String email, String password) async {
    await _db.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  static Future<void> register(
      String nama, String email, String password) async {
    final auth = await _db.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );
    final user = auth.user;
    if (user != null) {
      await _db.from('profiles').insert({
        'id': user.id,
        'nama': nama.trim(),
      });
    }
  }

  static Future<void> logout() async {
    await _db.auth.signOut();
  }

  static Future<String> getNamaUser() async {
    final user = currentUser;
    if (user == null) return '';
    try {
      final data = await _db
          .from('profiles')
          .select('nama')
          .eq('id', user.id)
          .maybeSingle();
      return (data?['nama'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }
}
