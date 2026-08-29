/// Mirrors com.harvestflow.api.domain.enums.PaymentReferenceType. Only two
/// values exist because there's no marketplace Order entity in this phase
/// — see the backend enum's javadoc.
enum PaymentReferenceType { purchaseInvoice, salesInvoice }

extension PaymentReferenceTypeX on PaymentReferenceType {
  String get apiValue => this == PaymentReferenceType.purchaseInvoice ? 'PURCHASE_INVOICE' : 'SALES_INVOICE';
  String get label => this == PaymentReferenceType.purchaseInvoice ? 'Purchase Invoice (farmer payout)' : 'Sales Invoice (buyer payment)';
}

/// Mirrors com.harvestflow.api.dto.payment.PaymentResponse. Every payment
/// produced by this app today came from the MOCK gateway — see
/// PaymentResponse.provider, which always reads "mock-payment-v1" — no real
/// money moves.
class PaymentRecordView {
  final String id;
  final String referenceType;
  final String referenceId;
  final double amount;
  final String currency;
  final String status; // PENDING / SUCCEEDED / FAILED
  final String provider;
  final String? gatewayReference;
  final String? failureReason;
  final String? note;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentRecordView({
    required this.id,
    required this.referenceType,
    required this.referenceId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    required this.gatewayReference,
    required this.failureReason,
    required this.note,
    required this.createdAt,
    required this.completedAt,
  });

  bool get isMock => provider.startsWith('mock');

  factory PaymentRecordView.fromApi(Map<String, dynamic> json) {
    return PaymentRecordView(
      id: json['id'] as String,
      referenceType: json['referenceType'] as String,
      referenceId: json['referenceId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      provider: json['provider'] as String,
      gatewayReference: json['gatewayReference'] as String?,
      failureReason: json['failureReason'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null ? null : DateTime.parse(json['completedAt'] as String),
    );
  }
}
