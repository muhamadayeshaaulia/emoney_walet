import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.100.218:8080'));

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    String? token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await _dio.get(
        '/v1/transactions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _transactions = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil riwayat: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('Belum ada transaksi.'))
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final String invoiceId = tx['invoice_id'];
                    final double amount = (tx['total_amount'] as num).toDouble();
                    final String status = tx['status'];
                    
                    bool isTopUp = invoiceId.startsWith('TOPUP');
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isTopUp ? Colors.green[100] : Colors.red[100],
                          child: Icon(
                            isTopUp ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isTopUp ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(isTopUp ? 'Top Up Saldo' : 'Pembayaran E-Commerce'),
                        subtitle: Text('Invoice: $invoiceId\nStatus: $status'),
                        trailing: Text(
                          '${isTopUp ? '+' : '-'} Rp ${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isTopUp ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
