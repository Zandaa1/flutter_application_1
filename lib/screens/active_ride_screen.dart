import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../services/background_service.dart';
import '../models/ride.dart';
import '../utils/agent_debug_log.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen>
    with SingleTickerProviderStateMixin {
  bool _isRideActive = false;
  bool _autoStartHandled = false;
  late AnimationController _blinkController;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  DateTime? _lastUpdatedAt;
  double? _distanceToDestinationMeters;
  double? _initialDistanceMeters;

  // TODO: Replace with actual ride data from route arguments
  final Ride _currentRide = Ride(
    id: '1',
    truckNumber: 'TRK-2025',
    destination: 'Manila Warehouse',
    destinationAddress: '123 Rizal Avenue, Manila',
    departureDate: DateTime.now(),
    arrivalDate: DateTime.now().add(const Duration(days: 2)),
    expectedDeparture: '08:00 AM',
    expectedArrival: '12:00 PM',
    status: RideStatus.current,
    remarks:
        'Priority delivery - Handle with care. Contact warehouse manager upon arrival.',
  );

  final double _destinationLat = 14.5995;
  final double _destinationLng = 120.9842;

  @override
  void initState() {
    super.initState();
    // #region agent log
    unawaited(AgentDebugLog.log(
      location: 'active_ride_screen.dart:initState',
      message: 'initState',
      runId: 'pre-fix',
      hypothesisId: 'H1',
      data: {'mounted': mounted},
    ));
    // #endregion
    // Blinking animation for GPS indicator
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Listen to background service updates (distance updates broadcast by service)
    BackgroundService.listenToService((data) {
      if (mounted && data != null) {
        setState(() {
          if (data['distanceMeters'] != null) {
            _distanceToDestinationMeters =
                (data['distanceMeters'] as num).toDouble();
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoStartHandled) return;
    _autoStartHandled = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['autoStart'] == true) {
      // Called after navigation from pre-ride screen — start immediately.
      WidgetsBinding.instance.addPostFrameCallback((_) => _startRide());
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    // #region agent log
    unawaited(AgentDebugLog.log(
      location: 'active_ride_screen.dart:_startLocationTracking',
      message: 'Start location tracking requested',
      runId: 'pre-fix',
      hypothesisId: 'H2',
    ));
    // #endregion
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // #region agent log
      unawaited(AgentDebugLog.log(
        location: 'active_ride_screen.dart:_startLocationTracking',
        message: 'Location services disabled',
        runId: 'pre-fix',
        hypothesisId: 'H2',
      ));
      // #endregion
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // #region agent log
      unawaited(AgentDebugLog.log(
        location: 'active_ride_screen.dart:_startLocationTracking',
        message: 'Location permission not granted',
        runId: 'pre-fix',
        hypothesisId: 'H2',
        data: {'permission': permission.toString()},
      ));
      // #endregion
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          if (!mounted) {
            return;
          }
          final dist = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _destinationLat,
            _destinationLng,
          );
          setState(() {
            _currentPosition = position;
            _lastUpdatedAt = DateTime.now();
            _distanceToDestinationMeters = dist;
            _initialDistanceMeters ??= dist;
          });
        }, onError: (error) {
          // #region agent log
          unawaited(AgentDebugLog.log(
            location: 'active_ride_screen.dart:_startLocationTracking',
            message: 'Position stream error',
            runId: 'pre-fix',
            hypothesisId: 'H2',
            data: {'error': error.toString()},
          ));
          // #endregion
        });
  }

  Future<void> _stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _openGoogleMaps() async {
    // #region agent log
    unawaited(AgentDebugLog.log(
      location: 'active_ride_screen.dart:_openGoogleMaps',
      message: 'Open maps requested',
      runId: 'pre-fix',
      hypothesisId: 'H3',
      data: {'lat': _destinationLat, 'lng': _destinationLng},
    ));
    // #endregion
    try {
      await MapsLauncher.launchCoordinates(
        _destinationLat,
        _destinationLng,
        _currentRide.destinationAddress,
      );
    } catch (e) {
      // #region agent log
      unawaited(AgentDebugLog.log(
        location: 'active_ride_screen.dart:_openGoogleMaps',
        message: 'Maps launcher threw',
        runId: 'pre-fix',
        hypothesisId: 'H3',
        data: {'error': e.toString()},
      ));
      // #endregion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps. Please install Google Maps.'),
          ),
        );
      }
    }
  }

  Future<void> _startRide() async {
    // #region agent log
    unawaited(AgentDebugLog.log(
      location: 'active_ride_screen.dart:_startRide',
      message: 'Start ride tapped',
      runId: 'pre-fix',
      hypothesisId: 'H4',
    ));
    // #endregion

    // 1. Start the background foreground service (shows persistent non-dismissable notification).
    //    NOTE: We do NOT pre-fire a local notification here because flutter_local_notifications
    //    notifications with ongoing:true are still swipeable on Android 14+. The foreground
    //    service notification (shown by the OS as part of the ForegroundService) is the only
    //    truly non-dismissable notification.
    //    TODO: Re-enable permission gate for production:
    //    final ok = await PermissionGuard.ensureActiveRideReady(context); if (!ok) return;
    final started = await BackgroundService.startService();
    if (started) {
      // 2. Send destination so notification shows distance immediately.
      BackgroundService.sendDestination(
        _destinationLat,
        _destinationLng,
        _currentRide.destination,
      );
    }

    // 3. Activate the ride UI and start the in-app GPS stream.
    setState(() {
      _isRideActive = true;
    });
    await _startLocationTracking();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride started — GPS tracking active'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _sendEmergencyAlert() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This will send an emergency notification to the admin. Use only in case of accidents, vehicle issues, or urgent situations.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
// Get colors carefully matching the error context natively.
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // TODO: Send emergency alert to server API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency alert sent to admin'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _endRide() async {
    // #region agent log
    unawaited(AgentDebugLog.log(
      location: 'active_ride_screen.dart:_endRide',
      message: 'End ride tapped',
      runId: 'pre-fix',
      hypothesisId: 'H5',
    ));
    // #endregion
    // Navigate to post-ride check screen
    final result = await Navigator.pushNamed(context, '/post-ride');

    // Only end ride if post-ride check was completed
    if (result == true) {
      // Stop background service and cancel the persistent notification.
      await BackgroundService.stopService();
      await _stopLocationTracking();

      setState(() {
        _isRideActive = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride ended successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // #region agent log
    unawaited(AgentDebugLog.log(
      location: 'active_ride_screen.dart:build',
      message: 'build',
      runId: 'pre-fix',
      hypothesisId: 'H1',
      data: {
        'isRideActive': _isRideActive,
        'hasPosition': _currentPosition != null,
      },
    ));
    // #endregion
    final currentLocationLabel = _currentPosition == null
        ? 'Getting GPS location…'
        : 'Lat ${_currentPosition!.latitude.toStringAsFixed(6)}, '
              'Lng ${_currentPosition!.longitude.toStringAsFixed(6)}';
    final lastUpdatedLabel = _lastUpdatedAt == null
        ? 'Last updated: --'
        : 'Last updated: ${DateFormat('hh:mm a').format(_lastUpdatedAt!)}';
    final isArrived = _distanceToDestinationMeters != null && _distanceToDestinationMeters! <= 250;
    
    final distanceLabel = _distanceToDestinationMeters == null
        ? 'Calculating…'
        : isArrived
            ? "You're here!"
            : _distanceToDestinationMeters! >= 1000
                ? '${(_distanceToDestinationMeters! / 1000).toStringAsFixed(1)} km to destination'
                : '${_distanceToDestinationMeters!.toStringAsFixed(0)} m to destination';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        actions: [
          if (_isRideActive)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blinking red indicator
                    AnimatedBuilder(
                      animation: _blinkController,
                      builder: (context, child) {
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(
                              _blinkController.value,
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GPS ACTIVE',
                      style: TextStyle(
                        color: cs.onTertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Route Info Card
            if (_isRideActive) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.route,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ride In Progress',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _RouteInfoRow(
                        icon: Icons.local_shipping,
                        label: 'Truck',
                        value: _currentRide.truckNumber,
                      ),
                      const SizedBox(height: 12),
                      _RouteInfoRow(
                        icon: Icons.location_on,
                        label: 'Destination',
                        value: _currentRide.destination,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Text(
                          _currentRide.destinationAddress,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.gps_fixed,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current location:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentLocationLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastUpdatedLabel,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Distance to destination
                      Row(
                        children: [
                          Icon(
                            Icons.directions_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Distance remaining:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  distanceLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                if (isArrived) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'You can now complete the job.',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_initialDistanceMeters != null &&
                          _distanceToDestinationMeters != null) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_initialDistanceMeters! -
                                          _distanceToDestinationMeters!) /
                                      _initialDistanceMeters!
                                          .clamp(1.0, double.infinity),
                              minHeight: 8,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Departure Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Departure:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentRide.expectedDeparture,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'EEEE, MMM dd, yyyy',
                                  ).format(_currentRide.departureDate),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Expected Arrival Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expected Arrival:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentRide.expectedArrival,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'EEEE, MMM dd, yyyy',
                                  ).format(_currentRide.arrivalDate),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Admin remarks
                      if (_currentRide.remarks != null &&
                          _currentRide.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cs.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 20,
                                color: cs.onSecondaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admin Instructions:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSecondaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _currentRide.remarks!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: cs.onSecondaryContainer,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Map Preview Card
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _openGoogleMaps,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primaryContainer.withOpacity(0.55),
                          cs.tertiaryContainer.withOpacity(0.55),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Map-like background pattern
                        Positioned.fill(
                          child: CustomPaint(painter: _MapPatternPainter()),
                        ),
                        // Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.navigation,
                                  size: 40,
                                  color: cs.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.map,
                                      color: cs.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Open to Google Maps',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],    
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 72,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Ride',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a ride to begin tracking',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_isRideActive) ...[
              const SizedBox(height: 16),
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Post-Trip Photos'),
                      subtitle: const Text('Upload delivery, condition, incidents'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.pushNamed(context, '/post-trip-photos'),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Fuel Receipts'),
                      subtitle: const Text('Upload and track fuel expenses'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/fuel-receipt',
                        arguments: _currentRide.id,
                      ),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.toll),
                      title: const Text('Toll Expense'),
                      subtitle: const Text('Add toll receipt & amount'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/add-toll'),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: const Text('Chat Support'),
                      subtitle: const Text('Message dispatch/admin'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: _endRide,
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text(
                    'COMPLETE JOB',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _sendEmergencyAlert,
                icon: Icon(Icons.warning_amber_rounded, color: cs.error),
                label: Text(
                  'Emergency Alert (Admin)',
                  style: tt.labelLarge?.copyWith(color: cs.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.error),
                  foregroundColor: cs.error,
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: _startRide,
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'START RIDE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.tertiary,
                    foregroundColor: cs.onTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// Custom painter for map-like background pattern
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw grid lines (like map streets)
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some diagonal "roads"
    paint.color = Colors.blue.withOpacity(0.2);
    paint.strokeWidth = 3;
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.8, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
