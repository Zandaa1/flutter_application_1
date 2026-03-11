import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showUpcoming = true;
  bool _showPast = false;
  
  // TODO: Replace with actual user data from authentication
  final String _driverName = "John";
  
  // TODO: Replace with actual data from API
  final List<Ride> _rides = [
    Ride(
      id: '1',
      truckNumber: 'TRK-2025',
      destination: 'Manila Warehouse',
      destinationAddress: '123 Rizal Avenue, Manila',
      date: DateTime.now(),
      expectedDeparture: '08:00 AM',
      expectedArrival: '12:00 PM',
      status: RideStatus.current,
    ),
    Ride(
      id: '2',
      truckNumber: 'TRK-2025',
      destination: 'Cebu Distribution Center',
      destinationAddress: '456 Osmena Blvd, Cebu City',
      date: DateTime.now().add(const Duration(days: 1)),
      expectedDeparture: '06:00 AM',
      expectedArrival: '02:00 PM',
      status: RideStatus.upcoming,
    ),
    Ride(
      id: '3',
      truckNumber: 'TRK-2025',
      destination: 'Davao Supply Hub',
      destinationAddress: '789 Roxas Avenue, Davao',
      date: DateTime.now().add(const Duration(days: 2)),
      expectedDeparture: '07:30 AM',
      expectedArrival: '01:00 PM',
      status: RideStatus.upcoming,
    ),
    Ride(
      id: '4',
      truckNumber: 'TRK-2025',
      destination: 'Quezon City Depot',
      destinationAddress: '321 Commonwealth Ave, QC',
      date: DateTime.now().subtract(const Duration(days: 1)),
      expectedDeparture: '09:00 AM',
      expectedArrival: '11:30 AM',
      status: RideStatus.past,
    ),
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  List<Ride> get _currentRides => _rides.where((r) => r.status == RideStatus.current).toList();
  List<Ride> get _upcomingRides => _rides.where((r) => r.status == RideStatus.upcoming).toList();
  List<Ride> get _pastRides => _rides.where((r) => r.status == RideStatus.past).toList();

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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Greeting
          Text(
            '${_getGreeting()}, $_driverName',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Current Rides (Always visible)
          if (_currentRides.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.navigation, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Current Ride',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._currentRides.map((ride) => _RideCard(ride: ride)),
            const SizedBox(height: 24),
          ],

          // Upcoming Rides (Collapsible)
          _SectionHeader(
            title: 'Upcoming Rides',
            count: _upcomingRides.length,
            isExpanded: _showUpcoming,
            onToggle: () {
              setState(() {
                _showUpcoming = !_showUpcoming;
              });
            },
          ),
          const SizedBox(height: 12),
          if (_showUpcoming)
            ..._upcomingRides.map((ride) => _RideCard(ride: ride)),
          if (_showUpcoming) const SizedBox(height: 24),

          // Past Rides (Collapsible)
          _SectionHeader(
            title: 'Past Rides',
            count: _pastRides.length,
            isExpanded: _showPast,
            onToggle: () {
              setState(() {
                _showPast = !_showPast;
              });
            },
          ),
          const SizedBox(height: 12),
          if (_showPast)
            ..._pastRides.map((ride) => _RideCard(ride: ride)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Row(
        children: [
          Icon(
            isExpanded ? Icons.expand_more : Icons.chevron_right,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;

  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final isCurrentRide = ride.status == RideStatus.current;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (ride.status == RideStatus.current) {
            Navigator.pushNamed(context, '/active-ride');
          } else if (ride.status == RideStatus.upcoming) {
            Navigator.pushNamed(context, '/pre-ride');
          }
          // Past rides are view-only
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Row: Departure, Date, Arrival
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Expected Departure
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Departure',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.expectedDeparture,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Date
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCurrentRide
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('MMM dd').format(ride.date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentRide
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expected Arrival
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Arrival',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.expectedArrival,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // Bottom Details
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.destination,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          ride.destinationAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Truck ${ride.truckNumber}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (isCurrentRide) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to view active ride',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (ride.status == RideStatus.upcoming) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/pre-ride');
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start Pre-Ride Check'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
