import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_picker_helper.dart';

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({super.key});

  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  XFile? _truckExteriorPhoto;
  XFile? _odometerPhoto;
  XFile? _manifestPhoto;
  bool _locationConfirmed = false;

  int get _completedCount =>
      (_truckExteriorPhoto != null ? 1 : 0) +
      (_odometerPhoto != null ? 1 : 0) +
      (_manifestPhoto != null ? 1 : 0) +
      (_locationConfirmed ? 1 : 0);

  bool get _allCompleted =>
      _truckExteriorPhoto != null &&
      _odometerPhoto != null &&
      _manifestPhoto != null &&
      _locationConfirmed;

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
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo uploaded: ${image.name}')),
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
        title: const Text('Post-Ride Check'),
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
                    'Post-Ride Inspection',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete all required checks before ending your trip',
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
            subtitle: 'Take photo of final truck condition',
            isCompleted: _truckExteriorPhoto != null,
            onTap: () => _pickImage('truck'),
          ),
          _ChecklistItem(
            icon: Icons.speed,
            title: 'Odometer Reading',
            subtitle: 'Capture ending mileage',
            isCompleted: _odometerPhoto != null,
            onTap: () => _pickImage('odometer'),
          ),
          _ChecklistItem(
            icon: Icons.description,
            title: 'Manifest Photo',
            subtitle: 'Upload signed delivery manifest',
            isCompleted: _manifestPhoto != null,
            onTap: () => _pickImage('manifest'),
          ),
          _ChecklistItem(
            icon: Icons.location_on,
            title: 'Location Verification',
            subtitle: 'Confirm you are at the destination',
            isCompleted: _locationConfirmed,
            onTap: () {
              // TODO: Verify GPS location matches destination
              setState(() {
                _locationConfirmed = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location verified')),
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: Validate photos/location before proceeding in production.
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Post-Ride Check'),
          ),
          if (!_allCompleted) ...[
            const SizedBox(height: 12),
            Text(
              'Please complete all checks to end your ride',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
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
