import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_picker_helper.dart';

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({Key? key}) : super(key: key);

  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  XFile? _truckExteriorPhoto;
  XFile? _odometerPhoto;
  XFile? _manifestPhoto;
  bool _locationConfirmed = false;

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
          ElevatedButton.icon(
            onPressed: _allCompleted
                ? () {
                    // Navigate back and end ride
                    Navigator.pop(context, true);
                  }
                : null,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Post-Ride Check'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: _allCompleted ? Colors.green : null,
            ),
          ),
          if (!_allCompleted) ...[
            const SizedBox(height: 12),
            Text(
              'Please complete all checks to end your ride',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted ? Colors.white : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: onTap,
          child: Text(isCompleted ? 'Change' : 'Upload'),
        ),
      ),
    );
  }
}
