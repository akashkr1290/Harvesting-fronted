import '../utils/api_dates.dart';

/// Fields captured on the Plot Selection form (SOW section 5.3 A).
class PlotSelection {
  final String location;
  final DateTime visitDate;
  final String commissionAgentName;
  final String farmerName;
  final String farmerPhone;
  final String village;
  final int numberOfPlants;
  final DateTime harvestingDate;
  final String remark;
  final double volume;
  final double recovery;
  final double pulp;
  final String selectedCompany;
  final String plotCode;
  final String gpsNote;
  final String priority; // high, medium, low
  final String? photoPath;

  PlotSelection({
    required this.location,
    required this.visitDate,
    required this.commissionAgentName,
    required this.farmerName,
    required this.farmerPhone,
    required this.village,
    required this.numberOfPlants,
    required this.harvestingDate,
    this.remark = '',
    required this.volume,
    required this.recovery,
    required this.pulp,
    required this.selectedCompany,
    this.plotCode = '',
    this.gpsNote = '',
    this.priority = 'medium',
    this.photoPath,
  });

  /// Body for POST /api/cases and PUT /api/cases/{id}/plot-selection
  /// (PlotSelectionRequest on the backend).
  Map<String, dynamic> toJson() => {
        'location': location,
        'visitDate': formatApiDate(visitDate),
        'commissionAgentName': commissionAgentName,
        'farmerName': farmerName,
        'farmerPhone': farmerPhone,
        'village': village,
        'numberOfPlants': numberOfPlants,
        'harvestingDate': formatApiDate(harvestingDate),
        'remark': remark,
        'volume': volume,
        'recovery': recovery,
        'pulp': pulp,
        'selectedCompany': selectedCompany,
        'plotCode': plotCode,
        'gpsNote': gpsNote,
        'priority': priority,
        'photoPath': photoPath,
      };

  /// Plot Selection fields are flattened directly onto CaseDetailResponse
  /// rather than nested, since they're always present from case creation.
  factory PlotSelection.fromCaseJson(Map<String, dynamic> json) {
    return PlotSelection(
      location: json['location'] as String,
      visitDate: parseApiDate(json['visitDate'] as String),
      commissionAgentName: json['commissionAgentName'] as String? ?? '',
      farmerName: json['farmerName'] as String,
      farmerPhone: json['farmerPhone'] as String? ?? '',
      village: json['village'] as String,
      numberOfPlants: (json['numberOfPlants'] as num?)?.toInt() ?? 0,
      harvestingDate: parseApiDate(json['harvestingDate'] as String),
      remark: json['remark'] as String? ?? '',
      volume: (json['volume'] as num?)?.toDouble() ?? 0,
      recovery: (json['recovery'] as num?)?.toDouble() ?? 0,
      pulp: (json['pulp'] as num?)?.toDouble() ?? 0,
      selectedCompany: json['selectedCompany'] as String,
      plotCode: json['plotCode'] as String? ?? '',
      gpsNote: json['gpsNote'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      photoPath: json['photoPath'] as String?,
    );
  }
}
