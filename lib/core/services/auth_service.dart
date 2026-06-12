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

  static Future<String?> loginWithGoogle() async {
    try {
      // Pass the Web Client ID directly to avoid cached values from the old project
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: '597810091743-i8evv5etr1qeusnmgrm0o66m41ies577.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) return "Dibatalkan oleh user";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 1. Login Firebase dengan Google Credential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // 2. Ambil Firebase Token
      String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) return "Gagal mendapatkan token Firebase";

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
        return null; // Berhasil, tidak ada error
      }
      return "Gagal login di backend: ${response.data}";
    } catch (e) {
      debugPrint('Google Login Error: $e');
      if (e is DioException) {
        return "Network Error: ${e.message} - ${e.response?.data}";
      }
      return "Google Login Error: $e";
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
    // saved_email dan saved_password TIDAK dihapus agar fingerprint tetap bisa dipakai
  }

  static Future<String?> register(String email, String password) async {
    try {
      // 1. Buat akun di Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Ambil Firebase Token
      String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) return "Gagal mendapatkan token Firebase";

      // 3. Register ke backend Golang (akan mengirim SMTP OTP)
      final response = await DioClient.instance.post(
        ApiConstants.register,
        data: {'firebase_token': firebaseToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        String jwtToken = response.data['data']['access_token'];
        String userName = response.data['data']['user']['name'] ?? 'Pengguna E-Money';
        await _storage.write(key: 'auth_token', value: jwtToken);
        await _storage.write(key: 'user_name', value: userName);
        
        await _storage.write(key: 'saved_email', value: email);
        await _storage.write(key: 'saved_password', value: password);
        return null; // Berhasil
      }
      return "Gagal mendaftar di backend: ${response.data['message']}";
    } catch (e) {
      debugPrint('Register Error: $e');
      if (e is DioException) {
        return "Network Error: ${e.message} - ${e.response?.data}";
      } else if (e is FirebaseAuthException) {
        return "Firebase Error: ${e.message}";
      }
      return "Register Error: $e";
    }
  }

  static Future<bool> verifyEmailOtp(String code) async {
    try {
      String? token = await getToken();
      if (token == null) return false;

      final response = await DioClient.instance.post(
        ApiConstants.verifyEmailOtp,
        data: {'code': code},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Verify Email OTP Error: $e');
      return false;
    }
  }
}
