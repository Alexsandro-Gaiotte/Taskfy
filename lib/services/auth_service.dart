import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static const String _usersKey = 'users_list';
  static const String _currentUserKey = 'current_user';
  static const String _salt = 'TaskfySecretSalt2024';

  /// Hashes a given password via SHA-256 with a local static salt
  String hashPassword(String password) {
    final saltedPassword = password + _salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Registra novo usuário se e-mail ainda não existir
  Future<UserModel?> registerUser(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usersData = prefs.getStringList(_usersKey) ?? [];

    for (var userJson in usersData) {
      final user = UserModel.fromJson(userJson);
      if (user.email == email) {
        throw Exception('Usuário já cadastrado com este email!');
      }
    }

    final newUser = UserModel(
      id: const Uuid().v4(),
      name: name,
      email: email,
      hashedPassword: hashPassword(password),
    );

    usersData.add(newUser.toJson());
    await prefs.setStringList(_usersKey, usersData);
    
    // Auto-login upon registration
    await prefs.setString(_currentUserKey, newUser.toJson());
        
    return newUser;
  }

  /// Login de usuário checando email e comparando os hash de senha
  Future<UserModel?> loginUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usersData = prefs.getStringList(_usersKey) ?? [];

    final inputHash = hashPassword(password);

    for (var userJson in usersData) {
      final user = UserModel.fromJson(userJson);
      if (user.email == email && user.hashedPassword == inputHash) {
        // Salva a sessao atual
        await prefs.setString(_currentUserKey, user.toJson());
        return user;
      }
    }
    return null; // Credenciais incorretas ou não encontradas
  }

  /// Recupera o usuario atualmente logado, caso exista.
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_currentUserKey);
    if (jsonStr != null) {
      return UserModel.fromJson(jsonStr);
    }
    return null;
  }

  /// Realiza o Logout da sessao.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}
