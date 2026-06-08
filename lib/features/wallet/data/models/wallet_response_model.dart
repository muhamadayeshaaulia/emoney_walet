class BalanceResponseModel {
  final double balance;
  final String? message;

  BalanceResponseModel({required this.balance, this.message});

  factory BalanceResponseModel.fromJson(Map<String, dynamic> json) {
    return BalanceResponseModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
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
