import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';

class ReceiptPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ReceiptPage({super.key, required this.data});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _captureAndSave() async {
    setState(() => _isSaving = true);
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final path = '/storage/emulated/0/Download/Struk_EMS_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Struk berhasil disimpan ke Galeri!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTopUp = widget.data['type'] == 'topup';
    final amount = (widget.data['amount'] as num?)?.toDouble() ?? 0;
    final invoiceId = widget.data['invoice_id'] ?? '-';
    final String rawDate = widget.data['date'] ?? '';
    final paymentMethod = widget.data['payment_method'] ?? '';
    
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  color: Colors.grey[50],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08), 
                          blurRadius: 15, 
                          offset: const Offset(0, 5)
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // HEADER STRUK
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/logo/logo.png',
                                height: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text(
                                    'E-MS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'E-Money Mamah Saya',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          isTopUp ? 'Top Up Berhasil' : 'Transaksi Berhasil', 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                        const SizedBox(height: 8),
                        Text(displayDate, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 32),
                        // KONTEN TRANSAKSI
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              _buildRow('Jenis Transaksi', isTopUp ? 'Top Up Saldo' : 'Pembayaran'),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Divider(height: 1, color: Colors.black12),
                              ),
                              if (isTopUp && paymentMethod.isNotEmpty) ...[
                                _buildRow('Metode Pembayaran', paymentMethod),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Divider(height: 1, color: Colors.black12),
                                ),
                              ],
                              _buildRow('No. Invoice', invoiceId),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Divider(height: 1, color: Colors.black12),
                              ),
                              _buildRow('Nominal', 'Rp ${CurrencyFormatter.format(amount)}', isBold: true, valueColor: AppColors.primaryColor),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Divider(height: 1, color: Colors.black12),
                              ),
                              _buildRow('Status', 'Berhasil', valueColor: Colors.green, isBold: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // FOOTER STRUK
                        const Text(
                          'Terima kasih telah menggunakan E-MS',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              // TOMBOL AKSI (Tidak ikut ter-screenshot)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _captureAndSave,
                        icon: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.download, color: Colors.white),
                        label: Text(_isSaving ? 'Menyimpan...' : 'Download Struk', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Kembali', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
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
