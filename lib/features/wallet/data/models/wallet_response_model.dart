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
    return BalanceResponseModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
      invoiceId: json['invoice_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      date: json['date'] as String?,
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
