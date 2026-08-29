enum ListingStatus { draft, published, closed }

extension ListingStatusX on ListingStatus {
  String get apiValue => name.toUpperCase();

  String get label {
    switch (this) {
      case ListingStatus.draft:
        return 'Draft';
      case ListingStatus.published:
        return 'Published';
      case ListingStatus.closed:
        return 'Closed';
    }
  }
}

ListingStatus listingStatusFromApi(String value) {
  return ListingStatus.values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => throw ArgumentError('Unknown listing status from API: $value'),
  );
}
