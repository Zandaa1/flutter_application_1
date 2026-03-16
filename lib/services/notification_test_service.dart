import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class TripAssignmentNotification {
  final String title;
  final String message;
  final DateTime createdAt;

  const TripAssignmentNotification({
    required this.title,
    required this.message,
    required this.createdAt,
  });
}

class NotificationTestService {
  static final ValueNotifier<TripAssignmentNotification?> notificationNotifier =
      ValueNotifier<TripAssignmentNotification?>(null);

  static void sendTripAssignedNotification({
    required DateTime tripDate,
    required String destination,
  }) {
    final dateLabel = DateFormat('MMM dd, yyyy').format(tripDate);

    notificationNotifier.value = TripAssignmentNotification(
      title: 'New Trip Assignment',
      message:
          'You have received a trip.\nDate: $dateLabel\nDestination: $destination',
      createdAt: DateTime.now(),
    );
  }

  static TripAssignmentNotification? consumeNotification() {
    final notification = notificationNotifier.value;
    notificationNotifier.value = null;
    return notification;
  }
}