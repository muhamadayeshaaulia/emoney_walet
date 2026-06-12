class BalanceResponseModel {
  final double balance;
  final String? message;
  final String? invoiceId;
  final double? amount;
  final String? date;

  BalanceResponseModel({
    required this.balance, 
    this.message,
    this.invoiceId,
    this.amount,
    this.date,
  });

  factory BalanceResponseModel.fromJson(Map<String, dynamic> json) {
    // Menyesuaikan dengan format be-emoney:
    // { "success": true, "data": { "balance": 10000 } }
    // atau jika topup: { "success": true, "data": { "balance": ..., "amount": ... } }
    final data = json['data'] ?? json; // Fallback jika tidak ada 'data'
    
    return BalanceResponseModel(
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
      invoiceId: data['invoice_id'] as String?,
      amount: (data['amount'] as num?)?.toDouble(),
      date: data['created_at'] as String? ?? json['date'] as String?,
    );
  }
}

class PaymentResponseModel {
  final String message;

  PaymentResponseModel({required this.message});

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      message: json['message'] as String? ?? 'Pembayaran berhasil',
    );
  }
}
