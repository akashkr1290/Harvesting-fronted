import '../utils/api_dates.dart';

class HarvestCompletion {
  final DateTime actualDate;
  final int actualBagsOrCrates;
  final double actualWeight;
  final String qualityNotes;
  final String wastageNotes;
  final double finalVolume;
  final double finalRecovery;
  final double finalPulp;
  final String remarks;
  final String? weightSlipFileName; // mock reference to uploaded file

  HarvestCompletion({
    required this.actualDate,
    required this.actualBagsOrCrates,
    required this.actualWeight,
    this.qualityNotes = '',
    this.wastageNotes = '',
    required this.finalVolume,
    required this.finalRecovery,
    required this.finalPulp,
    this.remarks = '',
    this.weightSlipFileName,
  });

  /// Body for POST /api/cases/{id}/harvest-completion (HarvestCompletionRequest).
  Map<String, dynamic> toJson() => {
        'actualDate': formatApiDate(actualDate),
        'actualBagsOrCrates': actualBagsOrCrates,
        'actualWeight': actualWeight,
        'qualityNotes': qualityNotes,
        'wastageNotes': wastageNotes,
        'finalVolume': finalVolume,
        'finalRecovery': finalRecovery,
        'finalPulp': finalPulp,
        'remarks': remarks,
        'weightSlipFileName': weightSlipFileName,
      };

  factory HarvestCompletion.fromJson(Map<String, dynamic> json) {
    return HarvestCompletion(
      actualDate: parseApiDate(json['actualDate'] as String),
      actualBagsOrCrates: (json['actualBagsOrCrates'] as num?)?.toInt() ?? 0,
      actualWeight: (json['actualWeight'] as num).toDouble(),
      qualityNotes: json['qualityNotes'] as String? ?? '',
      wastageNotes: json['wastageNotes'] as String? ?? '',
      finalVolume: (json['finalVolume'] as num?)?.toDouble() ?? 0,
      finalRecovery: (json['finalRecovery'] as num?)?.toDouble() ?? 0,
      finalPulp: (json['finalPulp'] as num?)?.toDouble() ?? 0,
      remarks: json['remarks'] as String? ?? '',
      weightSlipFileName: json['weightSlipFileName'] as String?,
    );
  }
}
