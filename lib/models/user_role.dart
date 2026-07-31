/// All roles defined in the SOW (section 3).
enum UserRole {
  admin,
  plotSelection,
  planning,
  godown,
  supervisor,
  purchaseAccount,
  pickupPerson,
  transportPerson,
  laborCoordinator,
  eicherDriver,
}

extension UserRoleX on UserRole {
  /// Matches the Java enum constant name exactly (e.g. PLOT_SELECTION) —
  /// used in JWT role claims, request bodies, and @PreAuthorize checks.
  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.plotSelection:
        return 'PLOT_SELECTION';
      case UserRole.planning:
        return 'PLANNING';
      case UserRole.godown:
        return 'GODOWN';
      case UserRole.supervisor:
        return 'SUPERVISOR';
      case UserRole.purchaseAccount:
        return 'PURCHASE_ACCOUNT';
      case UserRole.pickupPerson:
        return 'PICKUP_PERSON';
      case UserRole.transportPerson:
        return 'TRANSPORT_PERSON';
      case UserRole.laborCoordinator:
        return 'LABOR_COORDINATOR';
      case UserRole.eicherDriver:
        return 'EICHER_DRIVER';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.plotSelection:
        return 'Plot Selection Team';
      case UserRole.planning:
        return 'Planning Team';
      case UserRole.godown:
        return 'Godown Team';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.purchaseAccount:
        return 'Purchase Account Team';
      case UserRole.pickupPerson:
        return 'Pickup Person';
      case UserRole.transportPerson:
        return 'Transport Person';
      case UserRole.laborCoordinator:
        return 'Labor Coordinator';
      case UserRole.eicherDriver:
        return 'Eicher Truck Driver';
    }
  }

  /// One-line description of what this role does, shown on the login/role picker.
  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Creates users, controls masters, monitors everything';
      case UserRole.plotSelection:
        return 'Visits plot, selects for harvesting, submits selection report';
      case UserRole.planning:
        return 'Plans harvesting for next day and allocates operational details';
      case UserRole.godown:
        return 'Issues and reconciles packing material';
      case UserRole.supervisor:
        return 'Confirms harvesting completion, uploads weight slip';
      case UserRole.purchaseAccount:
        return 'Creates purchase invoice and calculates cost';
      case UserRole.pickupPerson:
        return 'Handles pickup coordination and driver/advance details';
      case UserRole.transportPerson:
        return 'Adds transporter name and cost';
      case UserRole.laborCoordinator:
        return 'Adds labor/local labor contractor and cost';
      case UserRole.eicherDriver:
        return 'Confirms loading, transit, and delivery milestones';
    }
  }
}

/// Parses the backend's UPPER_SNAKE_CASE enum name back into a UserRole.
/// Throws if the backend ever sends a role this app doesn't know about —
/// better to fail loudly than silently mis-route someone's permissions.
UserRole userRoleFromApi(String value) {
  return UserRole.values.firstWhere(
    (r) => r.apiValue == value,
    orElse: () => throw ArgumentError('Unknown role from API: $value'),
  );
}
