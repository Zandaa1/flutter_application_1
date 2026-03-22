import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/background_service.dart';
import '../services/mock_backend_service.dart';
import '../services/notification_test_service.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  bool _serviceEnabled = false;
  LocationPermission? _permission;
  Position? _currentPosition;
  String? _error;
  bool _isStreaming = false;
  bool _isStreamingLiveUpdate = false;
  bool _isMockActiveRideNotificationRunning = false;
  Map<String, Object?> _activeRideState = const <String, Object?>{};
  StreamSubscription<Position>? _positionSubscription;
  String? _deviceId;
  String? _deviceModel;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _refreshActiveRideState();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    if (!mounted) {
      return;
    }

    setState(() {
      _serviceEnabled = serviceEnabled;
      _permission = permission;
    });
  }

  Future<void> _refreshActiveRideState() async {
    final activeRide = await MockBackendService.getActiveRide();
    if (!mounted) {
      return;
    }
    setState(() {
      _activeRideState = activeRide;
      _isMockActiveRideNotificationRunning = activeRide['isActive'] == true;
    });
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String? deviceId;
    String? deviceModel;

    try {
      if (kIsWeb) {
        deviceId = 'Web';
        deviceModel = 'Browser';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
        deviceModel = iosInfo.utsname.machine;
      } else {
        final info = await deviceInfo.deviceInfo;
        deviceId = info.data['id']?.toString();
        deviceModel = info.data['model']?.toString();
      }
    } catch (_) {
      deviceId = null;
      deviceModel = null;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _deviceId = deviceId;
      _deviceModel = deviceModel;
    });
  }

  Future<void> _showDeviceMismatchDialog() async {
    final deviceId = _deviceId ?? 'Unknown';
    final deviceModel = _deviceModel ?? 'Unknown';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Mismatch Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This account is locked to a different device. Please contact the admin to update the registered device.',
            ),
            const SizedBox(height: 12),
            Text('Device model: $deviceModel'),
            const SizedBox(height: 4),
            Text('Device ID: $deviceId'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Contact Admin'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission() async {
    final permission = await Geolocator.requestPermission();

    if (!mounted) {
      return;
    }

    setState(() {
      _permission = permission;
      _error = null;
    });
  }

  Future<void> _getCurrentPosition() async {
    setState(() {
      _error = null;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _serviceEnabled = false;
        _error = 'Location services are disabled.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _permission = permission;
        _error = 'Location permission is not granted.';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _serviceEnabled = true;
      _permission = permission;
      _currentPosition = position;
    });
  }

  Future<void> _startStreaming() async {
    setState(() {
      _error = null;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _serviceEnabled = false;
        _error = 'Location services are disabled.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _permission = permission;
        _error = 'Location permission is not granted.';
      });
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          (position) {
            if (!mounted) {
              return;
            }
            setState(() {
              _currentPosition = position;
            });
            if (_isStreamingLiveUpdate || _isMockActiveRideNotificationRunning) {
              final destination = _isMockActiveRideNotificationRunning
                  ? 'Manila Warehouse'
                  : "Philippine Women's University Manila";
              final destinationLat = _isMockActiveRideNotificationRunning
                  ? 14.5995
                  : 14.5746;
              final destinationLng = _isMockActiveRideNotificationRunning
                  ? 120.9842
                  : 120.9922;
              final routeDistance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                destinationLat,
                destinationLng,
              );
              NotificationTestService.sendLiveUpdateNotification(
                distanceMeters: routeDistance,
                destination: destination,
                currentLat: position.latitude,
                currentLng: position.longitude,
              );
            }
            if (_isMockActiveRideNotificationRunning) {
              BackgroundService.sendLocationUpdate(
                lat: position.latitude,
                lng: position.longitude,
                accuracyMeters: position.accuracy,
                at: DateTime.now(),
              );
              unawaited(
                MockBackendService.setActiveRide(
                  isActive: true,
                  updatedBy: 'admin_tools_mock',
                  tripId: 'mock-admin-ride',
                  destinationName: 'Manila Warehouse',
                  destinationLat: 14.5995,
                  destinationLng: 120.9842,
                ),
              );
              unawaited(
                MockBackendService.addLocationPing(
                  LocationPing(
                    lat: position.latitude,
                    lng: position.longitude,
                    accuracyMeters: position.accuracy,
                    at: DateTime.now(),
                  ),
                ),
              );
              unawaited(_refreshActiveRideState());
            }
          },
          onError: (error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _error = error.toString();
            });
          },
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _serviceEnabled = true;
      _permission = permission;
      _isStreaming = true;
    });
  }

  Future<void> _stopStreaming() async {
    await _positionSubscription?.cancel();
    await NotificationTestService.cancelLiveUpdateNotification();

    if (!mounted) {
      return;
    }

    setState(() {
      _isStreaming = false;
      _isStreamingLiveUpdate = false;
    });
  }

  Future<void> _startLiveUpdateTest() async {
    setState(() {
      _isStreamingLiveUpdate = true;
    });
    if (!_isStreaming) {
      await _startStreaming();
    }
  }

  Future<void> _stopLiveUpdateTest() async {
    setState(() {
      _isStreamingLiveUpdate = false;
    });
    await NotificationTestService.cancelLiveUpdateNotification();
    if (_isStreaming) {
      await _stopStreaming();
    }
  }

  Future<void> _sendTestTripNotification() async {
    final testTripDate = DateTime.now().add(const Duration(days: 1));
    const testDestination = 'Manila Warehouse';

    await NotificationTestService.sendTripAssignedNotification(
      tripDate: testTripDate,
      destination: testDestination,
      truckNumber: 'TRK-2025',
      tripCode: 'TEST-TRIP-001',
      eta: '12:00 PM',
      testMode: true,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Improved test trip notification sent')),
    );
  }

  Future<void> _startMockActiveRideNotification() async {
    const destinationLat = 14.5995;
    const destinationLng = 120.9842;
    const destinationName = 'Manila Warehouse';

    final started = await BackgroundService.startService();
    if (!started) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start active ride mock notification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    BackgroundService.sendDestination(
      destinationLat,
      destinationLng,
      destinationName,
    );
    await NotificationTestService.sendRideStartedNotification(
      destination: destinationName,
    );
    await MockBackendService.setActiveRide(
      isActive: true,
      updatedBy: 'admin_tools_mock',
      tripId: 'mock-admin-ride',
      destinationName: destinationName,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isMockActiveRideNotificationRunning = true;
    });
    await _startStreaming();
    await _refreshActiveRideState();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Active ride mock notification started (tracking to Manila Warehouse)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _stopMockActiveRideNotification() async {
    final stopped = await BackgroundService.stopService();
    await NotificationTestService.cancelLiveUpdateNotification();
    await MockBackendService.setActiveRide(
      isActive: false,
      updatedBy: 'admin_tools_mock',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isMockActiveRideNotificationRunning = false;
    });
    await _refreshActiveRideState();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          stopped
              ? 'Active ride mock notification stopped'
              : 'No active ride mock notification was running',
        ),
      ),
    );
  }

  String _activeRideSummary() {
    if (_activeRideState.isEmpty || _activeRideState['isActive'] != true) {
      return 'No active ride in mock backend';
    }

    final destination =
        (_activeRideState['destinationName'] as String?) ??
        'Unknown destination';
    final lat = (_activeRideState['lastLat'] as num?)?.toDouble();
    final lng = (_activeRideState['lastLng'] as num?)?.toDouble();
    final updatedAtRaw = _activeRideState['lastUpdatedAt'] as String?;
    final updatedAt = updatedAtRaw == null
        ? null
        : DateTime.tryParse(updatedAtRaw);
    final updatedBy = (_activeRideState['updatedBy'] as String?) ?? 'unknown';

    final locationText = (lat == null || lng == null)
        ? 'Last location: waiting for first GPS ping'
        : 'Last location: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    final timeText = updatedAt == null
        ? 'Updated: --'
        : 'Updated: ${DateFormat('hh:mm:ss a').format(updatedAt.toLocal())}';

    return 'Active mock ride → $destination\n$locationText\n$timeText\nSource: $updatedBy';
  }

  String _permissionLabel(LocationPermission? permission) {
    switch (permission) {
      case LocationPermission.always:
        return 'Always';
      case LocationPermission.whileInUse:
        return 'While in use';
      case LocationPermission.denied:
        return 'Denied';
      case LocationPermission.deniedForever:
        return 'Denied forever';
      case LocationPermission.unableToDetermine:
        return 'Unable to determine';
      default:
        return 'Unknown';
    }
  }

  String _positionLabel(Position? position) {
    if (position == null) {
      return 'No location yet';
    }

    return 'Lat ${position.latitude.toStringAsFixed(6)}, '
        'Lng ${position.longitude.toStringAsFixed(6)}\n'
        'Accuracy ${position.accuracy.toStringAsFixed(1)} m';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final permissionLabel = _permissionLabel(_permission);
    final positionLabel = _positionLabel(_currentPosition);
    final isDeniedForever = _permission == LocationPermission.deniedForever;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'GPS Test Console',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Admin only: use this screen to verify geolocator behavior.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service enabled: ${_serviceEnabled ? 'Yes' : 'No'}'),
                    const SizedBox(height: 8),
                    Text('Permission: $permissionLabel'),
                    const SizedBox(height: 12),
                    Text('Last position: $positionLabel'),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.security),
              label: const Text('Request Permission'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _getCurrentPosition,
              icon: const Icon(Icons.my_location),
              label: const Text('Get Current Position'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isStreaming ? null : _startStreaming,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Live Updates'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isStreaming ? _stopStreaming : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Live Updates'),
            ),
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Extra Button Tests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'This simulates the device mismatch error that occurs when a driver tries to log in on a different device than the one registered to their account.',
            ),
            OutlinedButton.icon(
              onPressed: _showDeviceMismatchDialog,
              icon: const Icon(Icons.phonelink_erase),
              label: const Text('Simulate Device Mismatch'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _sendTestTripNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Send Test Trip Notification'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isStreamingLiveUpdate ? null : _startLiveUpdateTest,
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Start PWU Route Live Update Test'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isStreamingLiveUpdate ? _stopLiveUpdateTest : null,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop Live Update Test'),
            ),
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Active Ride Notification Mock',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Mimics the active ride foreground tracking notification status/location flow.',
            ),
            const SizedBox(height: 8),
            Text(
              _activeRideSummary(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isMockActiveRideNotificationRunning
                  ? null
                  : _startMockActiveRideNotification,
              icon: const Icon(Icons.local_shipping_rounded),
              label: const Text('Start Active Ride Mock Notification'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isMockActiveRideNotificationRunning
                  ? _stopMockActiveRideNotification
                  : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop Active Ride Mock Notification'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _refreshActiveRideState,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Active Ride Mock State'),
            ),

            if (isDeniedForever) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: Geolocator.openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
