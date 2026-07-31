class SalesInvoiceData {
  final String invoiceNumber;
  final String buyerCompany;
  final double salesRate;
  final double weight;
  final double taxPercent;
  final DateTime createdAt;

  SalesInvoiceData({
    required this.invoiceNumber,
    required this.buyerCompany,
    required this.salesRate,
    required this.weight,
    this.taxPercent = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => salesRate * weight;
  double get taxAmount => subtotal * (taxPercent / 100);
  double get total => subtotal + taxAmount;

  /// Body for POST /api/cases/{id}/sales-invoice (SalesInvoiceRequest).
  Map<String, dynamic> toJson() => {
        'buyerCompany': buyerCompany,
        'salesRate': salesRate,
        'weight': weight,
        'taxPercent': taxPercent,
      };

  factory SalesInvoiceData.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceData(
      invoiceNumber: json['invoiceNumber'] as String,
      buyerCompany: json['buyerCompany'] as String,
      salesRate: (json['salesRate'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}
