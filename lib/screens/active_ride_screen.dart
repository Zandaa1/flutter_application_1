import 'package:flutter/material.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({Key? key}) : super(key: key);

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  bool _isRideActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        actions: [
          if (_isRideActive)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _isRideActive ? Icons.navigation : Icons.local_shipping,
                      size: 64,
                      color: _isRideActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRideActive ? 'Ride In Progress' : 'No Active Ride',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRideActive
                          ? 'GPS tracking is active'
                          : 'Start a ride to begin tracking',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isRideActive) ...[
              _ActionButton(
                icon: Icons.map,
                label: 'Open Navigation',
                color: Colors.blue,
                onPressed: () {
                  // TODO: Launch Waze/Google Maps
                },
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.receipt,
                label: 'Upload Fuel Receipt',
                color: Colors.orange,
                onPressed: () {
                  // TODO: Upload fuel receipt
                },
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.chat,
                label: 'Chat with Admin',
                color: Colors.purple,
                onPressed: () {
                  // TODO: Open chat
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isRideActive = false;
                  });
                  // TODO: End ride and upload post-ride photos
                },
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
                onPressed: () {
                  setState(() {
                    _isRideActive = true;
                  });
                  // TODO: Start GPS tracking
                },
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
