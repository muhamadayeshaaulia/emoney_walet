import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'receipt_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];

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
      final response = await DioClient.instance.get(
        ApiConstants.transactions,
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
                    final String invoiceId = tx['invoice_id'] ?? 'N/A';
                    final double amount = (tx['total_amount'] as num?)?.toDouble() ?? (tx['amount'] as num?)?.toDouble() ?? 0.0;
                    final String status = tx['status'] ?? 'SUCCESS';
                    
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
                          '${isTopUp ? '+' : '-'} Rp ${CurrencyFormatter.format(amount)}',
                          style: TextStyle(
                            color: isTopUp ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptPage(
                                data: {
                                  'type': isTopUp ? 'topup' : 'pay',
                                  'amount': amount,
                                  'invoice_id': invoiceId,
                                  'payment_method': tx['payment_method'] ?? '',
                                  'date': tx['created_at'] ?? '',
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
