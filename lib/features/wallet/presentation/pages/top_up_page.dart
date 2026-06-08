import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/wallet_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../main.dart'; // for flutterLocalNotificationsPlugin

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    // Hanya ambil angka
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return const TextEditingValue(text: '');
    
    // Format ke ribuan dengan titik
    int value = int.parse(cleanText);
    String newText = formatNumber(value);
    
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  // Helper function untuk format angka (bisa dipakai di tempat lain)
  static String formatNumber(int value) {
    String str = value.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return result;
  }
}

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final TextEditingController _amountController = TextEditingController();
  final WalletRepository _repository = WalletRepository();
  bool _isLoading = false;

  final List<int> _presetAmounts = [100000, 200000, 300000, 500000, 1000000];

  void _selectPreset(int amount) {
    setState(() {
      _amountController.text = CurrencyInputFormatter.formatNumber(amount);
    });
  }

  Future<void> _processTopUp() async {
    // Ambil nilai asli (tanpa titik)
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal top up')),
      );
      return;
    }

    final double amount = double.tryParse(amountText) ?? 0;
    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal top up Rp 10.000')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final responseModel = await _repository.topUp(amount);
      if (responseModel != null) {
        // Notifikasi
        const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'emoney_topup_channel',
          'Notifikasi Top Up',
          channelDescription: 'Notifikasi saat saldo berhasil ditambahkan',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
        const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
        
        String formattedAmount = CurrencyInputFormatter.formatNumber(amount.toInt());
        
        await NotificationService.addNotification(
          'Top Up Berhasil! 💸', 
          'Saldo E-Money Mamah Saya bertambah Rp $formattedAmount',
          extraData: {
            'type': 'topup',
            'invoice_id': responseModel.invoiceId,
            'amount': responseModel.amount,
            'date': responseModel.date,
          }
        );

        await flutterLocalNotificationsPlugin.show(
          0,
          'Top Up Berhasil! 💸',
          'Saldo E-Money Mamah Saya bertambah Rp $formattedAmount',
          platformChannelSpecifics,
        );

        if (mounted) {
          Navigator.pop(context, true); // kembali dengan sukses
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Top Up Gagal')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hapus titik untuk mengecek apakah sesuai dengan preset
    String cleanText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');

    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Saldo')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Nominal Cepat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _presetAmounts.map((amount) {
                return ChoiceChip(
                  label: Text('Rp ${CurrencyInputFormatter.formatNumber(amount)}'),
                  selected: cleanText == amount.toString(),
                  onSelected: (selected) {
                    if (selected) _selectPreset(amount);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Atau Masukkan Nominal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                CurrencyInputFormatter(), // <-- Formatter format Rupiah
              ],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
                hintText: 'Minimal Rp 10.000',
              ),
              onChanged: (val) {
                setState(() {}); // Untuk trigger update state di ChoiceChip
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Top Up Sekarang', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
