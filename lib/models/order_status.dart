enum MarketOrderStatus { confirmed, completed, cancelled }

extension MarketOrderStatusX on MarketOrderStatus {
  String get apiValue => name.toUpperCase();

  String get label {
    switch (this) {
      case MarketOrderStatus.confirmed:
        return 'Confirmed';
      case MarketOrderStatus.completed:
        return 'Completed';
      case MarketOrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

MarketOrderStatus marketOrderStatusFromApi(String value) {
  return MarketOrderStatus.values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => throw ArgumentError('Unknown order status from API: $value'),
  );
}
