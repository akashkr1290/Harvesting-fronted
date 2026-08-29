enum OfferStatus { pending, accepted, rejected, withdrawn }

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
    }
  }
}

OfferStatus offerStatusFromApi(String value) {
  return OfferStatus.values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => throw ArgumentError('Unknown offer status from API: $value'),
  );
}
