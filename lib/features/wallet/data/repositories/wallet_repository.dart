import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../services/auth_service.dart'; // Nanti path ini menyesuaikan setelah dipindah

class WalletRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  // Fungsi Get Balance
  Future<double?> fetchBalance() async {
    String? token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        ApiConstants.wallet,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return (response.data['balance'] as num).toDouble();
      }
    } catch (e) {
      throw Exception('Gagal mengambil saldo: $e');
    }
    return null;
  }

  // Fungsi Top Up
  Future<double?> topUp(double amount) async {
    String? token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await _dio.post(
        ApiConstants.topUp,
        data: {'amount': amount},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return (response.data['balance'] as num).toDouble();
      }
    } catch (e) {
      throw Exception('Top Up Gagal: $e');
    }
    return null;
  }

  // Fungsi Pay Transaction
  Future<bool> payTransaction(String invoiceId, String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.pay}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'invoice_id': invoiceId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error jaringan: $e');
    }
  }
}
