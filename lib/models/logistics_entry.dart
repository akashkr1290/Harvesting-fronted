/// Steps 6, 8, 9, 10 in the SOW are structurally identical: a name, an
/// amount, an optional advance payment, optional remarks. Modeled as one
/// type with a `kind` tag rather than four near-duplicate classes.
enum LogisticsKind { pickup, transport, labor, localLabor }

extension LogisticsKindX on LogisticsKind {
  String get label {
    switch (this) {
      case LogisticsKind.pickup:
        return 'Pickup';
      case LogisticsKind.transport:
        return 'Transport';
      case LogisticsKind.labor:
        return 'Labor';
      case LogisticsKind.localLabor:
        return 'Local Labor';
    }
  }

  String get personLabel {
    switch (this) {
      case LogisticsKind.pickup:
        return 'Pickup Driver Name';
      case LogisticsKind.transport:
        return 'Transporter Name';
      case LogisticsKind.labor:
        return 'Labor Contractor Name';
      case LogisticsKind.localLabor:
        return 'Local Labor Contractor Name';
    }
  }
}

class LogisticsEntry {
  final LogisticsKind kind;
  final String personOrContractorName;
  final double amount;
  final double advancePayment;
  final String remarks;
  final DateTime enteredAt;

  LogisticsEntry({
    required this.kind,
    required this.personOrContractorName,
    required this.amount,
    this.advancePayment = 0,
    this.remarks = '',
    DateTime? enteredAt,
  }) : enteredAt = enteredAt ?? DateTime.now();

  /// Body for POST /api/cases/{id}/pickup, /transport, and the labor/
  /// localLabor fields inside LaborRequest — matches LogisticsLineDto,
  /// which has no `kind` field since the backend infers it from which
  /// endpoint (or which field of LaborRequest) the body arrived on.
  Map<String, dynamic> toJson() => {
        'personOrContractorName': personOrContractorName,
        'amount': amount,
        'advancePayment': advancePayment,
        'remarks': remarks,
      };

  /// Parses a LogisticsResponse, which does include `kind` (useful when
  /// reading pickup/transport/labor/localLabor back off a case's detail).
  factory LogisticsEntry.fromJson(Map<String, dynamic> json) {
    return LogisticsEntry(
      kind: _kindFromApi(json['kind'] as String),
      personOrContractorName: json['personOrContractorName'] as String,
      amount: (json['amount'] as num).toDouble(),
      advancePayment: (json['advancePayment'] as num?)?.toDouble() ?? 0,
      remarks: json['remarks'] as String? ?? '',
    );
  }
}

LogisticsKind _kindFromApi(String value) {
  switch (value) {
    case 'PICKUP':
      return LogisticsKind.pickup;
    case 'TRANSPORT':
      return LogisticsKind.transport;
    case 'LABOR':
      return LogisticsKind.labor;
    case 'LOCAL_LABOR':
      return LogisticsKind.localLabor;
    default:
      throw ArgumentError('Unknown logistics kind from API: $value');
  }
}
