import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> login(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) return "Gagal mendapatkan token Firebase";

      // Gunakan endpoint register untuk MENGIRIM OTP
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
        return "OTP_REQUIRED";
      }
      return "Login gagal: ${response.data}";
    } catch (e) {
      debugPrint('Login Error: $e');
      return "Terjadi kesalahan saat login";
    }
  }

  static Future<String?> loginWithGoogle() async {
    try {
      // Harus menggunakan serverClientId untuk Google Auth Firebase
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

      // 3. Tukar dengan JWT Golang & Kirim OTP
      final response = await DioClient.instance.post(
        ApiConstants.register,
        data: {'firebase_token': firebaseToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // 4. Simpan JWT Token di Secure Storage
        String jwtToken = response.data['data']['access_token'];
        String userName = response.data['data']['user']['name'] ?? 'Pengguna E-Money';
        await _storage.write(key: 'auth_token', value: jwtToken);
        await _storage.write(key: 'user_name', value: userName);
        return "OTP_REQUIRED"; 
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
    await GoogleSignIn().signOut(); // Supaya bisa pilih akun Google lain saat login lagi
    await _storage.delete(key: 'auth_token');
    // saved_email dan saved_password TIDAK dihapus agar fingerprint tetap bisa dipakai
  }

  static Future<String?> register(String name, String email, String password) async {
    try {
      // 1. Buat akun di Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Display Name di Firebase
      await userCredential.user?.updateDisplayName(name);

      // 2. Ambil Firebase Token (force refresh agar name masuk payload)
      String? firebaseToken = await userCredential.user?.getIdToken(true);
      if (firebaseToken == null) return "Gagal mendapatkan token Firebase";

      // 3. Register ke backend Golang (akan mengirim SMTP OTP)
      final response = await DioClient.instance.post(
        ApiConstants.register,
        data: {
          'firebase_token': firebaseToken,
          'name': name, // Kirim juga secara eksplisit kalau backend butuh
        },
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

  static Future<String?> verifyEmailOtp(String code) async {
    try {
      String? token = await getToken();
      if (token == null) return "Sesi tidak valid, silakan login ulang.";

      final response = await DioClient.instance.post(
        ApiConstants.verifyEmailOtp,
        data: {'code': code},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return null; // Sukses
      }
      return response.data['message'] ?? "Kode OTP tidak valid atau kedaluwarsa.";
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          return e.response?.data['message'] ?? "Kode OTP tidak valid atau kedaluwarsa.";
        }
        return "Kode OTP tidak valid atau kedaluwarsa.";
      }
      return "Terjadi kesalahan sistem";
    }
  }

  static Future<String?> resendEmailOtp() async {
    try {
      String? token = await getToken();
      if (token == null) return "Sesi tidak valid, silakan login ulang.";

      final response = await DioClient.instance.post(
        ApiConstants.otpSendEmail,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return null; // Sukses kirim ulang
      }
      return "Gagal mengirim ulang OTP.";
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          return e.response?.data['message'] ?? "Gagal mengirim ulang OTP.";
        }
      }
      return "Terjadi kesalahan saat mengirim ulang OTP.";
    }
  }

  static Future<String?> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      if (e is FirebaseAuthException) {
        return "Gagal: ${e.message}";
      }
      return "Terjadi kesalahan sistem";
    }
  }
}
