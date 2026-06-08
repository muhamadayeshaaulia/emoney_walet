import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double _balance = 0.0;
  bool _isLoading = true;
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.100.218:8080')); // Ganti jika IP berubah

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() => _isLoading = true);
    String? token = await AuthService.getToken();
    if (token == null) {
      _logout();
      return;
    }

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
      setState(() => _isLoading = false);
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

  void _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard E-Money', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
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
                        label: const Text('Top Up', style: TextStyle(color: Colors.white)),
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
              ],
            ),
          ),
    );
  }
}
