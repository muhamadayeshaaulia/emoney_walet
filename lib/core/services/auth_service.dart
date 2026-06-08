import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.100.218:8080')); // Ganti sesuai IP Backend jika perlu

  static Future<bool> login(String email, String password) async {
    try {
      // 1. Login Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Ambil Firebase Token
      String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) return false;

      // 3. Tukar dengan JWT Golang
      final response = await _dio.post(
        '/v1/auth/verify-token',
        data: {'firebase_token': firebaseToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // 4. Simpan JWT Token di Secure Storage
        String jwtToken = response.data['data']['access_token'];
        await _storage.write(key: 'auth_token', value: jwtToken);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _storage.delete(key: 'auth_token');
  }
}
