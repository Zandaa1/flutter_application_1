import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../services/background_service.dart';
import '../models/ride.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({Key? key}) : super(key: key);

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen>
    with SingleTickerProviderStateMixin {
  bool _isRideActive = false;
  late AnimationController _blinkController;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  DateTime? _lastUpdatedAt;
  
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
    remarks: 'Priority delivery - Handle with care. Contact warehouse manager upon arrival.',
  );
  
  final double _destinationLat = 14.5995;
  final double _destinationLng = 120.9842;

  @override
  void initState() {
    super.initState();
    // Blinking animation for GPS indicator
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Listen to background service updates
    BackgroundService.listenToService((data) {
      if (mounted && data != null) {
        // Handle GPS tracking updates from background service
        print('Background service update: $data');
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPosition = position;
        _lastUpdatedAt = DateTime.now();
      });
    });
  }

  Future<void> _stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _openGoogleMaps() async {
    try {
      await MapsLauncher.launchCoordinates(
        _destinationLat,
        _destinationLng,
        _currentRide.destinationAddress,
      );
    } catch (e) {
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
    // Start background service for GPS tracking
    bool started = await BackgroundService.startService();
    
    if (started) {
      setState(() {
        _isRideActive = true;
      });
      await _startLocationTracking();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride started - GPS tracking active'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _sendEmergencyAlert() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text(
          'This will send an emergency notification to the admin. Use only in case of accidents, vehicle issues, or urgent situations.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
    // Navigate to post-ride check screen
    final result = await Navigator.pushNamed(context, '/post-ride');
    
    // Only end ride if post-ride check was completed
    if (result == true) {
      // Stop background service
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
    final currentLocationLabel = _currentPosition == null
      ? 'Getting for GPS Location...'
      : 'Lat ${_currentPosition!.latitude.toStringAsFixed(6)}, '
        'Lng ${_currentPosition!.longitude.toStringAsFixed(6)}';
    final lastUpdatedLabel = _lastUpdatedAt == null
      ? 'Last updated: --'
      : 'Last updated: ${DateFormat('hh:mm a').format(_lastUpdatedAt!)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        actions: [
          if (_isRideActive)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
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
                            color: Colors.red.withOpacity(_blinkController.value),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GPS ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
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
                    elevation: 4,
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
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.gps_fixed, size: 20, color: Colors.grey[600]),
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
                          // Departure Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
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
                                      DateFormat('EEEE, MMM dd, yyyy').format(_currentRide.departureDate),
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
                              Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
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
                                      DateFormat('EEEE, MMM dd, yyyy').format(_currentRide.arrivalDate),
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
                          if (_currentRide.remarks != null && _currentRide.remarks!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.assignment,
                                    size: 20,
                                    color: Colors.orange,
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
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _currentRide.remarks!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
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
                    elevation: 4,
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
                              Colors.blue.shade50,
                              Colors.green.shade50,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Map-like background pattern
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MapPatternPainter(),
                              ),
                            ),
                            // Content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.navigation,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
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
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Tap to Open Navigation',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _currentRide.destination,
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Corner badge
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'GPS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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
                            size: 64,
                            color: Colors.grey,
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
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
            if (_isRideActive) ...[
              _ActionButton(
                icon: Icons.receipt,
                label: 'Upload Fuel Receipt',
                color: Colors.orange,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/fuel-receipt',
                    arguments: _currentRide.id,
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.chat,
                label: 'Chat with Staff',
                color: Colors.purple,
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.warning,
                label: 'Emergency Alert',
                color: Colors.red,
                onPressed: _sendEmergencyAlert,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _endRide,
                icon: const Icon(Icons.stop_circle),
                label: const Text('End Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startRide,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
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
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: color),
      ),
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
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
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
