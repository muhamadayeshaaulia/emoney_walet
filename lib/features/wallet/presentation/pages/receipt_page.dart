import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReceiptPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isTopUp = data['type'] == 'topup';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final invoiceId = data['invoice_id'] ?? '-';
    final String rawDate = data['date'] ?? '';
    
    String displayDate = '-';
    if (rawDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawDate);
        displayDate = DateFormat('dd MMM yyyy, HH:mm').format(parsed);
      } catch (e) {
        displayDate = rawDate;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Transaksi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              Text(
                isTopUp ? 'Top Up Berhasil' : 'Transaksi Berhasil', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(displayDate, style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRow('Jenis Transaksi', isTopUp ? 'Top Up Saldo E-Money' : 'Pembayaran'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1),
                    ),
                    _buildRow('No. Invoice', invoiceId),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1),
                    ),
                    _buildRow('Nominal', 'Rp ${CurrencyFormatter.format(amount)}', isBold: true, valueColor: Colors.blueAccent),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1),
                    ),
                    _buildRow('Status', 'Berhasil', valueColor: Colors.green, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Kembali', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
