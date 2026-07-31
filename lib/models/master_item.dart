enum MasterCategory {
  locations,
  villages,
  commissionAgents,
  farmers,
  companies,
  cropTypes,
  vehicleTypes,
  packingItems,
  unitsOfMeasure,
}

extension MasterCategoryX on MasterCategory {
  /// Matches the Java enum constant name exactly — used as the path
  /// segment in /api/master-data/{category}.
  String get apiValue {
    switch (this) {
      case MasterCategory.locations:
        return 'LOCATIONS';
      case MasterCategory.villages:
        return 'VILLAGES';
      case MasterCategory.commissionAgents:
        return 'COMMISSION_AGENTS';
      case MasterCategory.farmers:
        return 'FARMERS';
      case MasterCategory.companies:
        return 'COMPANIES';
      case MasterCategory.cropTypes:
        return 'CROP_TYPES';
      case MasterCategory.vehicleTypes:
        return 'VEHICLE_TYPES';
      case MasterCategory.packingItems:
        return 'PACKING_ITEMS';
      case MasterCategory.unitsOfMeasure:
        return 'UNITS_OF_MEASURE';
    }
  }

  String get label {
    switch (this) {
      case MasterCategory.locations:
        return 'Locations';
      case MasterCategory.villages:
        return 'Villages';
      case MasterCategory.commissionAgents:
        return 'Commission Agents';
      case MasterCategory.farmers:
        return 'Farmers';
      case MasterCategory.companies:
        return 'Companies';
      case MasterCategory.cropTypes:
        return 'Product / Crop Types';
      case MasterCategory.vehicleTypes:
        return 'Vehicle Types';
      case MasterCategory.packingItems:
        return 'Packing Material Items';
      case MasterCategory.unitsOfMeasure:
        return 'Units of Measure';
    }
  }
}

class MasterItem {
  final String id;
  String name;
  bool active;

  MasterItem({required this.id, required this.name, this.active = true});

  factory MasterItem.fromJson(Map<String, dynamic> json) {
    return MasterItem(
      id: json['id'] as String,
      name: json['name'] as String,
      active: json['active'] as bool? ?? true,
    );
  }
}
