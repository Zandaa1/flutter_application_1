class Ride {
  final String id;
  final String truckNumber;
  final String destination;
  final String destinationAddress;
  final DateTime date;
  final String expectedDeparture;
  final String expectedArrival;
  final RideStatus status;

  Ride({
    required this.id,
    required this.truckNumber,
    required this.destination,
    required this.destinationAddress,
    required this.date,
    required this.expectedDeparture,
    required this.expectedArrival,
    required this.status,
  });
}

enum RideStatus {
  upcoming,
  current,
  past,
}
