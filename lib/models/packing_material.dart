import '../utils/api_dates.dart';

/// One line item of packing material — used for both issue (Godown → Packing
/// team) and return (Godown reconciliation) since the shape is identical.
class PackingMaterialLine {
  final String itemName;
  final double quantity;
  final String unit;

  PackingMaterialLine({
    required this.itemName,
    required this.quantity,
    this.unit = 'pcs',
  });

  /// Matches PackingLineDto on the backend, used both in request bodies and
  /// response parsing (same shape both directions).
  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'quantity': quantity,
        'unit': unit,
      };

  factory PackingMaterialLine.fromJson(Map<String, dynamic> json) {
    return PackingMaterialLine(
      itemName: json['itemName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
    );
  }
}

class PackingMaterialRecord {
  final DateTime dateTime;
  final String handledBy; // receiver name (issue) or reconciled-by (return)
  final List<PackingMaterialLine> lines;
  final String remarks;

  PackingMaterialRecord({
    required this.dateTime,
    required this.handledBy,
    required this.lines,
    this.remarks = '',
  });

  /// PackingRecordResponse on the backend — note recordedAt maps to our
  /// local `dateTime` field name.
  factory PackingMaterialRecord.fromJson(Map<String, dynamic> json) {
    return PackingMaterialRecord(
      dateTime: parseApiInstant(json['recordedAt'] as String),
      handledBy: json['handledBy'] as String,
      lines: (json['lines'] as List<dynamic>? ?? [])
          .map((l) => PackingMaterialLine.fromJson(l as Map<String, dynamic>))
          .toList(),
      remarks: json['remarks'] as String? ?? '',
    );
  }
}
