import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _DashboardCard(
              icon: Icons.camera_alt,
              title: 'Pre-Ride Check',
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/pre-ride');
              },
            ),
            _DashboardCard(
              icon: Icons.navigation,
              title: 'Active Ride',
              color: Colors.emerald,
              onTap: () {
                Navigator.pushNamed(context, '/active-ride');
              },
            ),
            _DashboardCard(
              icon: Icons.history,
              title: 'Ride History',
              color: Colors.orange,
              onTap: () {
                // TODO: Navigate to ride history
              },
            ),
            _DashboardCard(
              icon: Icons.chat,
              title: 'Messages',
              color: Colors.purple,
              onTap: () {
                // TODO: Navigate to messages
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Extension for emerald color
extension CustomColors on Colors {
  static const emerald = Color(0xFF10B981);
}
