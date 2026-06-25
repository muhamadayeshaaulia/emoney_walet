import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/wallet_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../main.dart'; // for flutterLocalNotificationsPlugin
import '../../../../core/theme/app_colors.dart';

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

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'gopay',
      'name': 'GoPay',
      'category': 'E-Wallet',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Colors.blue,
    },
    {
      'id': 'dana',
      'name': 'DANA',
      'category': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'color': Colors.lightBlue,
    },
    {
      'id': 'shopeepay',
      'name': 'ShopeePay',
      'category': 'E-Wallet',
      'icon': Icons.shopping_bag_outlined,
      'color': Colors.orange,
    },
    {
      'id': 'bca',
      'name': 'Bank BCA',
      'category': 'Transfer Bank',
      'icon': Icons.account_balance,
      'color': Colors.blue[900],
    },
    {
      'id': 'mandiri',
      'name': 'Bank Mandiri',
      'category': 'Transfer Bank',
      'icon': Icons.account_balance,
      'color': Colors.yellow[800],
    },
  ];

  String _selectedMethod = 'gopay';

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
      final selectedMethodName = _paymentMethods.firstWhere((e) => e['id'] == _selectedMethod)['name'];
      final responseModel = await _repository.topUp(amount, paymentMethod: selectedMethodName);
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
          'Top Up Berhasil', 
          'Saldo E-Money Mamah Saya bertambah Rp $formattedAmount via $selectedMethodName',
          extraData: {
            'type': 'topup',
            'invoice_id': responseModel.invoiceId,
            'amount': responseModel.amount,
            'date': responseModel.date,
            'payment_method': selectedMethodName,
          }
        );

        await flutterLocalNotificationsPlugin.show(
          0,
          'Top Up Berhasil',
          'Saldo E-Money Mamah Saya bertambah Rp $formattedAmount via $selectedMethodName',
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
      appBar: AppBar(
        title: const Text('Top Up Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                Color(0xFF193475),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Nominal Cepat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 12),
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
                    selectedColor: AppColors.primarySurface,
                    labelStyle: TextStyle(
                      color: cleanText == amount.toString() ? AppColors.primaryColor : AppColors.slate600,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Atau Masukkan Nominal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(), // <-- Formatter format Rupiah
                ],
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  hintText: 'Minimal Rp 10.000',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                onChanged: (val) {
                  setState(() {}); // Untuk trigger update state di ChoiceChip
                },
              ),
              const SizedBox(height: 28),
              const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paymentMethods.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  final isSelected = _selectedMethod == method['id'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMethod = method['id'];
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primarySurface.withOpacity(0.4) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryColor : AppColors.line,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: method['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              method['icon'],
                              color: method['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  method['category'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: method['id'],
                            groupValue: _selectedMethod,
                            activeColor: AppColors.primaryColor,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedMethod = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processTopUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Top Up Sekarang', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
