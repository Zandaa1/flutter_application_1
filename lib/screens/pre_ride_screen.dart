import 'package:flutter/material.dart';

class PreRideScreen extends StatefulWidget {
  const PreRideScreen({Key? key}) : super(key: key);

  @override
  State<PreRideScreen> createState() => _PreRideScreenState();
}

class _PreRideScreenState extends State<PreRideScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Ride Check'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pre-Ride Inspection',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete all required checks before starting your trip',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ChecklistItem(
            icon: Icons.local_shipping,
            title: 'Truck Exterior Photo',
            subtitle: 'Take photo of truck condition',
            onTap: () {
              // TODO: Implement photo capture
            },
          ),
          _ChecklistItem(
            icon: Icons.speed,
            title: 'Odometer Reading',
            subtitle: 'Capture starting mileage',
            onTap: () {
              // TODO: Implement odometer photo
            },
          ),
          _ChecklistItem(
            icon: Icons.description,
            title: 'Manifest Photo',
            subtitle: 'Upload delivery manifest',
            onTap: () {
              // TODO: Implement manifest photo
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Submit pre-ride check
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pre-ride check submitted')),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Pre-Ride Check'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChecklistItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: onTap,
          child: const Text('Upload'),
        ),
      ),
    );
  }
}
