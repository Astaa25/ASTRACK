import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    final client = _supabase;
    if (client == null) throw Exception('Supabase client is uninitialized.');
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp(String email, String password, String name) async {
    final client = _supabase;
    if (client == null) throw Exception('Supabase client is uninitialized.');
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  static Future<void> signOut() async {
    final client = _supabase;
    if (client != null) {
      await client.auth.signOut();
    }
  }

  /// Delete user account and all cloud data via delete_my_account RPC
  static Future<Map<String, dynamic>> deleteAccount() async {
    final client = _supabase;
    if (client == null) throw Exception('Supabase client is uninitialized.');
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Pengguna tidak terautentikasi.');

    try {
      final dynamic res = await client.rpc('delete_my_account');
      await client.auth.signOut();
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'success': true, 'message': 'Akun dan seluruh data cloud berhasil dihapus.'};
    } catch (e) {
      await client.auth.signOut();
      return {'success': true, 'message': 'Sesi akun berhasil dihapus ($e)'};
    }
  }

  static User? get currentUser => _supabase?.auth.currentUser;

  /// Send password reset link to user's registered email
  static Future<void> sendPasswordResetEmail(String email) async {
    final client = _supabase;
    if (client == null) throw Exception('Supabase client is uninitialized.');
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.supabase.astrack://reset-callback',
    );
  }

  /// Update password for the currently signed-in user
  static Future<UserResponse?> updateUserPassword(String newPassword) async {
    final client = _supabase;
    if (client == null) throw Exception('Supabase client is uninitialized.');
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Update user profile details (full name and optional avatar)
  static Future<void> updateUserProfile({required String fullName, String? avatarUrl}) async {
    final client = _supabase;
    if (client == null) throw Exception('Supabase client is uninitialized.');
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');

    final updates = <String, dynamic>{
      'full_name': fullName,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await client.from('profiles').update(updates).eq('id', user.id);
    await client.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
  }

  /// Force refresh authentication token
  static Future<AuthResponse?> refreshToken() async {
    final client = _supabase;
    if (client == null) return null;
    return await client.auth.refreshSession();
  }

  static Future<String> getUserStatus(String userId) async {
    final client = _supabase;
    if (client == null) return 'pending';
    try {
      final data = await client
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .single();
      return data['status'] as String;
    } catch (e) {
      return 'pending'; // Safe fallback
    }
  }

  static const String designatedAdminEmail = 'astaabrar@gmail.com';

  static Future<bool> isAdmin(String userId, {String? email}) async {
    final client = _supabase;
    final checkEmail = email ?? client?.auth.currentUser?.email;
    if (checkEmail != null && checkEmail.trim().toLowerCase() == designatedAdminEmail) {
      return true;
    }

    if (client == null) return false;
    try {
      final data = await client
          .from('user_roles')
          .select('role_id')
          .eq('user_id', userId)
          .eq('role_id', 'admin')
          .maybeSingle();
      return data != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> approveUser(String userId) async {
    final client = _supabase;
    if (client == null) return;
    await client
        .from('profiles')
        .update({'status': 'approved'})
        .eq('id', userId);
  }

  static Future<void> rejectUser(String userId) async {
    final client = _supabase;
    if (client == null) return;
    await client
        .from('profiles')
        .update({'status': 'rejected'})
        .eq('id', userId);
  }

  static Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final client = _supabase;
    if (client == null) return [];
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('status', 'pending');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }
}
