import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart' show themeModeNotifier;
import '../models/ride.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showUpcoming = true;
  bool _showPast = false;

  final String _driverName = "Alexander Reyes";

  final List<Ride> _rides = [
    Ride(
      id: '1',
      truckNumber: 'ABC-1234',
      destination: 'Manila Warehouse',
      destinationAddress: '123 Rizal Avenue, Manila',
      departureDate: DateTime.now(),
      arrivalDate: DateTime.now(),
      expectedDeparture: '08:00 AM',
      expectedArrival: '12:00 PM',
      status: RideStatus.current,
      remarks:
          'Priority delivery - Handle with care. Contact warehouse manager upon arrival.',
      jobId: 'JOB-2024-001',

    ),
    Ride(
      id: '2',
      truckNumber: 'DEF-5678',
      destination: 'Cebu Distribution Center',
      destinationAddress: '456 Osmena Blvd, Cebu City',
      departureDate: DateTime.now().add(const Duration(days: 1)),
      arrivalDate: DateTime.now().add(const Duration(days: 3)),
      expectedDeparture: '06:00 AM',
      expectedArrival: '02:00 PM',
      status: RideStatus.upcoming,
      remarks: 'Fragile items on board. Avoid rough roads if possible.',
      jobId: 'JOB-2024-002',
    ),
    Ride(
      id: '3',
      truckNumber: 'TRK-2025',
      destination: 'Davao Supply Hub',
      destinationAddress: '789 Roxas Avenue, Davao',
      departureDate: DateTime.now().add(const Duration(days: 2)),
      arrivalDate: DateTime.now().add(const Duration(days: 4)),
      expectedDeparture: '07:30 AM',
      expectedArrival: '01:00 PM',
      status: RideStatus.upcoming,
      jobId: 'JOB-2024-003',
    ),
    Ride(
      id: '4',
      truckNumber: 'TRK-2025',
      destination: 'Quezon City Depot',
      destinationAddress: '321 Commonwealth Ave, QC',
      departureDate: DateTime.now().subtract(const Duration(days: 2)),
      arrivalDate: DateTime.now().subtract(const Duration(days: 1)),
      expectedDeparture: '09:00 AM',
      expectedArrival: '11:30 AM',
      status: RideStatus.past,
      remarks: 'Completed successfully. No issues reported.',
      jobId: 'JOB-2024-004',
    ),
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<Ride> get _currentRides =>
      _rides.where((r) => r.status == RideStatus.current).toList();
  List<Ride> get _upcomingRides =>
      _rides.where((r) => r.status == RideStatus.upcoming).toList();
  List<Ride> get _pastRides =>
      _rides.where((r) => r.status == RideStatus.past).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark ||
                  (mode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) ==
                          Brightness.dark);
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                onPressed: () {
                  themeModeNotifier.value =
                      isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            tooltip: 'Log out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // SOS Trigger Default action
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                'EMERGENCY SOS',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Are you sure you want to trigger the panic alert? We will notify the admin.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Emergency alert sent to admin'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: const Text('TRIGGER'),
                ),
              ],
            ),
          );
        },
        backgroundColor: cs.error,
        icon: Icon(Icons.warning_rounded, color: cs.onError),
        label: Text(
          'SOS / PANIC',
          style: TextStyle(
            color: cs.onError,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    _getGreeting(),
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _driverName,
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Rides
                  if (_currentRides.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: cs.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ongoing Trip',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._currentRides.map((ride) => _RideCard(ride: ride)),
                    const SizedBox(height: 24),
                  ],

                  // Upcoming Rides
                  _SectionHeader(
                    title: 'Upcoming Trips',
                    count: _upcomingRides.length,
                    isExpanded: _showUpcoming,
                    onToggle: () =>
                        setState(() => _showUpcoming = !_showUpcoming),
                  ),
                  if (_showUpcoming) ...[
                    const SizedBox(height: 16),
                    ..._upcomingRides.map((ride) => _RideCard(ride: ride)),
                  ],
                  const SizedBox(height: 16),

                  // Past Rides
                  _SectionHeader(
                    title: 'Trip History',
                    count: _pastRides.length,
                    isExpanded: _showPast,
                    onToggle: () => setState(() => _showPast = !_showPast),
                  ),
                  if (_showPast) ...[
                    const SizedBox(height: 16),
                    ..._pastRides.map((ride) => _RideCard(ride: ride)),
                  ],
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          ],
        ),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideCard extends StatefulWidget {
  final Ride ride;

  const _RideCard({required this.ride});

  @override
  State<_RideCard> createState() => _RideCardState();
}

class _RideCardState extends State<_RideCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.ride.status == RideStatus.current) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isCurrentRide = widget.ride.status == RideStatus.current;

    return FadeTransition(
      opacity: isCurrentRide
          ? Tween<double>(begin: 0.8, end: 1.0).animate(_blinkController)
          : AlwaysStoppedAnimation(1.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isCurrentRide
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isCurrentRide ? cs.primary : cs.outlineVariant,
            width: isCurrentRide ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (widget.ride.status == RideStatus.current) {
                Navigator.pushNamed(context, '/active-ride');
              } else if (widget.ride.status == RideStatus.upcoming) {
                Navigator.pushNamed(context, '/pre-ride');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header with Truck ID
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isCurrentRide)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'IN PROGRESS',
                          style: tt.bodyLarge?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TRUCK: ${widget.ride.truckNumber}',
                        style: tt.labelLarge?.copyWith(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if ((widget.ride.jobId?.isNotEmpty ?? false))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'JOB ID: ${widget.ride.jobId}',
                          style: tt.labelLarge?.copyWith(
                            fontSize: 13,
                            color: cs.onSecondaryContainer,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Route Visual
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.outline, width: 3),
                            color: cs.surface,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          color: cs.outlineVariant,
                        ),
                        Icon(
                          Icons.location_on,
                          color: isCurrentRide ? cs.error : cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispatch Origin',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            widget.ride.expectedDeparture,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.ride.destination,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            widget.ride.destinationAddress,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: cs.outlineVariant.withValues(alpha: 0.6)),
                const SizedBox(height: 12),

                // Footer (Date & Duration)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(widget.ride.departureDate),
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (isCurrentRide)
                      Row(
                        children: [
                          Text(
                            'View Details',
                            style: tt.labelLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
// Final attempt to fix compiler sync






