import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({Key? key}) : super(key: key);

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  bool _serviceEnabled = false;
  LocationPermission? _permission;
  Position? _currentPosition;
  String? _error;
  bool _isStreaming = false;
  StreamSubscription<Position>? _positionSubscription;
  String? _deviceId;
  String? _deviceModel;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
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

    if (!mounted) {
      return;
    }

    setState(() {
      _isStreaming = false;
    });
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
            Text('Extra Button Tests',
            style: Theme.of(context).textTheme.headlineSmall,),
            Text(
              'This simulates the device mismatch error that occurs when a driver tries to log in on a different device than the one registered to their account.',
            ),
            OutlinedButton.icon(
              onPressed: _showDeviceMismatchDialog,
              icon: const Icon(Icons.phonelink_erase),
              label: const Text('Simulate Device Mismatch'),
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
