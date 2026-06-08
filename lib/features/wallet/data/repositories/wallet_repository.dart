import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/network/dio_client.dart';
import '../models/wallet_response_model.dart';

class WalletRepository {
  // Fungsi Get Balance
  Future<BalanceResponseModel?> fetchBalance() async {
    String? token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await DioClient.instance.get(
        ApiConstants.wallet,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return BalanceResponseModel.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Gagal mengambil saldo: $e');
    }
    return null;
  }

  // Fungsi Top Up
  Future<BalanceResponseModel?> topUp(double amount) async {
    String? token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await DioClient.instance.post(
        ApiConstants.topUp,
        data: {'amount': amount},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return BalanceResponseModel.fromJson(response.data);
      }
    } catch (e) {
      throw Exception('Top Up Gagal: $e');
    }
    return null;
  }

  // Fungsi Pay Transaction
  Future<PaymentResponseModel?> payTransaction(String invoiceId, String token) async {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentResponseModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Error jaringan: $e');
    }
  }
}
