import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_config.dart';

class SupabaseAuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<UserModel?> registerUser(String name, String email, String password) async {
    try {
      final AuthResponse res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      final user = res.user;
      if (user != null) {
        // Automatically insert into public 'profiles' table if it exists
        // We remove the silent catch here so the developer can see RLS errors
        await _client.from('profiles').insert({
          'id': user.id,
          'name': name,
          'email': email,
        });

        return UserModel(
          id: user.id,
          name: name,
          email: email,
          hashedPassword: '', // Not needed locally anymore
        );
      }
      return null;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro ao registrar: $e');
    }
  }

  Future<UserModel?> loginUser(String email, String password) async {
    try {
      final AuthResponse res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        String name = user.userMetadata?['name'] ?? '';
        return UserModel(
          id: user.id,
          name: name,
          email: email,
          hashedPassword: '',
        );
      }
      return null;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro ao logar: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      String name = user.userMetadata?['name'] ?? '';
      return UserModel(
        id: user.id,
        name: name,
        email: user.email ?? '',
        hashedPassword: '',
      );
    }
    return null;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Erro ao enviar e-mail de recuperação: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, name, email')
          .eq('email', email)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Erro ao buscar perfil por email: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, name, email')
          .eq('id', id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Erro ao buscar perfil por ID: $e');
      return null;
    }
  }
}
