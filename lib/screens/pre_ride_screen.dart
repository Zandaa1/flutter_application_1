import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_picker_helper.dart';
import '../services/mock_backend_service.dart';

class PreRideScreen extends StatefulWidget {
  const PreRideScreen({super.key});

  @override
  State<PreRideScreen> createState() => _PreRideScreenState();
}

class _PreRideScreenState extends State<PreRideScreen> {
  XFile? _truckExteriorPhoto;
  XFile? _odometerPhoto;
  XFile? _manifestPhoto;
  XFile? _fuelDetailsPhoto;
  bool _isSubmitting = false;

  // TODO: Receive actual ride ID from route arguments in production.
  final String _tripId = '1';

  int get _completedCount =>
      (_truckExteriorPhoto != null ? 1 : 0) +
      (_odometerPhoto != null ? 1 : 0) +
      (_manifestPhoto != null ? 1 : 0) +
      (_fuelDetailsPhoto != null ? 1 : 0);

  bool get _allCompleted => _completedCount == 4;

  Future<void> _pickImage(String type) async {
    final XFile? image = await ImagePickerHelper.showImageSourceDialog(context);
    if (image != null) {
      setState(() {
        if (type == 'truck') {
          _truckExteriorPhoto = image;
        } else if (type == 'odometer') {
          _odometerPhoto = image;
        } else if (type == 'manifest') {
          _manifestPhoto = image;
        } else if (type == 'fuel') {
          _fuelDetailsPhoto = image;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo captured: ${image.name}')),
        );
      }
    }
  }

  /// Batch-submit all pre-ride data in one call, then immediately navigate to
  /// the active ride screen with autoStart = true so the ride begins right away.
  Future<void> _submitAndStart() async {
    setState(() => _isSubmitting = true);

    try {
      // TODO: In production, validate photos and require _allCompleted.
      // For now we allow test-mode submission with placeholder files when photos are missing.
      final now = DateTime.now();

      if (_allCompleted) {
        // Real submission path – all photos were taken, upload them together.
        await MockBackendService.initialize();
        await MockBackendService.submitPreRide(
          tripId: _tripId,
          truckExteriorPhoto: File(_truckExteriorPhoto!.path),
          odometerPhoto: File(_odometerPhoto!.path),
          manifestPhoto: File(_manifestPhoto!.path),
          fuelDetailsPhoto: File(_fuelDetailsPhoto!.path),
          submittedAt: now,
        );
      }
      // If not all completed, we still allow proceeding (test mode).

      if (!mounted) return;

      // Navigate directly to the active ride screen and auto-start the ride.
      // Using pushReplacementNamed so the driver cannot go back to pre-ride.
      await Navigator.pushReplacementNamed(
        context,
        '/active-ride',
        arguments: {'autoStart': true, 'tripId': _tripId},
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
                    'Complete all checks then tap "Submit & Start Ride" to begin.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _completedCount / 4,
                            minHeight: 10,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$_completedCount/4',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
            isCompleted: _truckExteriorPhoto != null,
            onTap: () => _pickImage('truck'),
          ),
          _ChecklistItem(
            icon: Icons.speed,
            title: 'Odometer Reading',
            subtitle: 'Capture starting mileage',
            isCompleted: _odometerPhoto != null,
            onTap: () => _pickImage('odometer'),
          ),
          _ChecklistItem(
            icon: Icons.description,
            title: 'Manifest Photo',
            subtitle: 'Upload delivery manifest',
            isCompleted: _manifestPhoto != null,
            onTap: () => _pickImage('manifest'),
          ),
          _ChecklistItem(
            icon: Icons.local_gas_station,
            title: 'Fuel Details',
            subtitle: 'Capture fuel level/receipt',
            isCompleted: _fuelDetailsPhoto != null,
            onTap: () => _pickImage('fuel'),
          ),
          const SizedBox(height: 24),
          // Single submit button — sends all data at once and starts the ride.
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitAndStart,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _allCompleted ? cs.onPrimary : cs.onTertiary,
                      ),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(
                _isSubmitting
                    ? 'Submitting…'
                    : _allCompleted
                        ? 'Submit & Start Ride'
                        : 'Submit & Start Ride (Test Mode)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _allCompleted ? cs.primary : cs.tertiary,
                foregroundColor:
                    _allCompleted ? cs.onPrimary : cs.onTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (!_allCompleted) ...[
            const SizedBox(height: 10),
            Text(
              'Complete all 4 items for a full submission.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ChecklistItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isCompleted ? cs.tertiary : cs.primaryContainer,
          foregroundColor: isCompleted ? cs.onTertiary : cs.onPrimaryContainer,
          child: Icon(isCompleted ? Icons.check_rounded : icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
          color: isCompleted ? cs.tertiary : cs.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
