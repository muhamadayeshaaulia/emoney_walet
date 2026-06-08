import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

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
      final response = await DioClient.instance.post(
        ApiConstants.verifyToken,
        data: {'firebase_token': firebaseToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // 4. Simpan JWT Token di Secure Storage
        String jwtToken = response.data['data']['access_token'];
        String userName = response.data['data']['user']['name'] ?? 'Pengguna E-Money';
        await _storage.write(key: 'auth_token', value: jwtToken);
        await _storage.write(key: 'user_name', value: userName);
        
        // Simpan email & password untuk keperluan Fingerprint Login nantinya
        await _storage.write(key: 'saved_email', value: email);
        await _storage.write(key: 'saved_password', value: password);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  static Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false; // Dibatalkan oleh user

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 1. Login Firebase dengan Google Credential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // 2. Ambil Firebase Token
      String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) return false;

      // 3. Tukar dengan JWT Golang
      final response = await DioClient.instance.post(
        ApiConstants.verifyToken,
        data: {'firebase_token': firebaseToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // 4. Simpan JWT Token di Secure Storage
        String jwtToken = response.data['data']['access_token'];
        String userName = response.data['data']['user']['name'] ?? 'Pengguna E-Money';
        await _storage.write(key: 'auth_token', value: jwtToken);
        await _storage.write(key: 'user_name', value: userName);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google Login Error: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  static Future<String?> getSavedEmail() async {
    return await _storage.read(key: 'saved_email');
  }

  static Future<String?> getSavedPassword() async {
    return await _storage.read(key: 'saved_password');
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _storage.delete(key: 'auth_token');
    // Note: saved_email dan saved_password TIDAK dihapus agar fingerprint tetap bisa dipakai
  }
}
