class PurchaseInvoiceData {
  final String invoiceNumber;
  final double rate; // per unit
  final double weight;
  final bool includeCommission;
  final double commissionAmount;
  final bool includePackingCost;
  final double packingCost;
  final bool includeTransportCost;
  final double transportCost;
  final double otherCharges;
  final double deductions;
  final double additions;
  final DateTime createdAt;

  PurchaseInvoiceData({
    required this.invoiceNumber,
    required this.rate,
    required this.weight,
    this.includeCommission = true,
    this.commissionAmount = 0,
    this.includePackingCost = true,
    this.packingCost = 0,
    this.includeTransportCost = true,
    this.transportCost = 0,
    this.otherCharges = 0,
    this.deductions = 0,
    this.additions = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get baseAmount => rate * weight;

  /// Net payable to farmer — configurable components, admin decides which
  /// apply (see Working Approach doc, section 5).
  double get netPayable {
    double net = baseAmount;
    if (includeCommission) net -= commissionAmount;
    if (includePackingCost) net -= packingCost;
    if (includeTransportCost) net -= transportCost;
    net -= otherCharges;
    net -= deductions;
    net += additions;
    return net;
  }

  /// Body for POST /api/cases/{id}/purchase-invoice (PurchaseInvoiceRequest).
  /// invoiceNumber/createdAt aren't sent — the backend generates those.
  Map<String, dynamic> toJson() => {
        'rate': rate,
        'weight': weight,
        'includeCommission': includeCommission,
        'commissionAmount': commissionAmount,
        'includePackingCost': includePackingCost,
        'packingCost': packingCost,
        'includeTransportCost': includeTransportCost,
        'transportCost': transportCost,
        'otherCharges': otherCharges,
        'deductions': deductions,
        'additions': additions,
      };

  /// Parses PurchaseInvoiceResponse. baseAmount/netPayable are recomputed
  /// locally via the getters above rather than trusting the response's
  /// copies, so the two stay provably in sync.
  factory PurchaseInvoiceData.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceData(
      invoiceNumber: json['invoiceNumber'] as String,
      rate: (json['rate'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      includeCommission: json['includeCommission'] as bool? ?? true,
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble() ?? 0,
      includePackingCost: json['includePackingCost'] as bool? ?? true,
      packingCost: (json['packingCost'] as num?)?.toDouble() ?? 0,
      includeTransportCost: json['includeTransportCost'] as bool? ?? true,
      transportCost: (json['transportCost'] as num?)?.toDouble() ?? 0,
      otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0,
      additions: (json['additions'] as num?)?.toDouble() ?? 0,
    );
  }
}
