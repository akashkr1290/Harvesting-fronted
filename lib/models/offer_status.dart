enum OfferStatus { pending, accepted, rejected, withdrawn, expired }

extension OfferStatusX on OfferStatus {
  String get apiValue => name.toUpperCase();

  String get label {
    switch (this) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.rejected:
        return 'Rejected';
      case OfferStatus.withdrawn:
        return 'Withdrawn';
      case OfferStatus.expired:
        return 'Expired';
    }
  }
}

OfferStatus offerStatusFromApi(String value) {
  return OfferStatus.values.firstWhere(
    (s) => s.apiValue == value,
    // Unknown values must not crash a screen when the backend is newer than the app.
    orElse: () => OfferStatus.expired,
  );
}
