import 'package:flutter/material.dart';
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
  
  // TODO: Replace with actual ride data from route arguments
  final Ride _currentRide = Ride(
    id: '1',
    truckNumber: 'TRK-2025',
    destination: 'Manila Warehouse',
    destinationAddress: '123 Rizal Avenue, Manila',
    date: DateTime.now(),
    expectedDeparture: '08:00 AM',
    expectedArrival: '12:00 PM',
    status: RideStatus.current,
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
    _blinkController.dispose();
    super.dispose();
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

  Future<void> _endRide() async {
    // Navigate to post-ride check screen
    final result = await Navigator.pushNamed(context, '/post-ride');
    
    // Only end ride if post-ride check was completed
    if (result == true) {
      // Stop background service
      await BackgroundService.stopService();
      
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
      body: Padding(
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
                          _RouteInfoRow(
                            icon: Icons.access_time,
                            label: 'Expected Arrival',
                            value: _currentRide.expectedArrival,
                          ),
                        ],
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
                icon: Icons.map,
                label: 'Open Google Maps',
                color: Colors.blue,
                onPressed: _openGoogleMaps,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.receipt,
                label: 'Upload Fuel Receipt',
                color: Colors.orange,
                onPressed: () {
                  Navigator.pushNamed(context, '/fuel-receipt');
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
              const Spacer(),
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
              const Spacer(),
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
