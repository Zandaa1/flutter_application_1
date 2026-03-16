class FuelReceiptRecord {
  final String photoName;
  final double totalPesos;
  final double pricePerLiter;
  final double liters;
  final DateTime uploadedAt;

  const FuelReceiptRecord({
    required this.photoName,
    required this.totalPesos,
    required this.pricePerLiter,
    required this.liters,
    required this.uploadedAt,
  });
}

class FuelReceiptHistoryService {
  static final Map<String, List<FuelReceiptRecord>> _historyByTrip =
      <String, List<FuelReceiptRecord>>{};

  static List<FuelReceiptRecord> getHistoryForTrip(String tripId) {
    final history = _historyByTrip[tripId];
    if (history == null) {
      return const <FuelReceiptRecord>[];
    }

    return List<FuelReceiptRecord>.unmodifiable(history.reversed.toList());
  }

  static void addReceipt({
    required String tripId,
    required FuelReceiptRecord record,
  }) {
    final history = _historyByTrip.putIfAbsent(tripId, () => <FuelReceiptRecord>[]);
    history.add(record);
  }
}