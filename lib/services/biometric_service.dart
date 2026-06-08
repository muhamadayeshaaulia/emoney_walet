import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Gunakan Sidik Jari / Face ID untuk masuk ke E-Money Mamah Saya',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Membolehkan fallback PIN/Pattern HP
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
