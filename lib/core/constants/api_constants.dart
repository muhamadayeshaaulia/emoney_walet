class ApiConstants {
  static const String baseUrl = 'http://192.168.8.196:8081/v1';

  // Account endpoints
  static const String wallet = '/account'; // Dulu /wallet
  static const String transactions = '/account/transactions';

  // Payment endpoints
  static const String topUp = '/payment/topup';
  static const String pay = '/payment/transfer'; // Pindah dari /wallet/pay

  // Auth endpoints
  static const String verifyToken = '/auth/verify-token';
  static const String register = '/auth/register';
  static const String verifyEmailOtp = '/auth/verify-email-otp';

  // OTP endpoints
  static const String otpSendEmail = '/otp/send-email';
}