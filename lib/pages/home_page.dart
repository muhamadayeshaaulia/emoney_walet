import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _balance = 0.0;
  bool _isLoading = true;
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.100.218:8080')); 

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() => _isLoading = true);
    String? token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await _dio.get(
        '/v1/wallet',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _balance = (response.data['balance'] as num).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil saldo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _topUp() async {
    String? token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await _dio.post(
        '/v1/wallet/topup',
        data: {'amount': 500000}, // Sekali Top Up Rp 500.000
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _balance = (response.data['balance'] as num).toDouble();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Top Up Rp 500.000 Berhasil!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Top Up Gagal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('E-Money Mamah Saya', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo Anda', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  'Rp ${_balance.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _topUp,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Top Up Saldo', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _fetchBalance,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Refresh', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Center(
                  child: Text(
                    'Menunggu permintaan pembayaran dari E-Commerce...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
    );
  }
}
