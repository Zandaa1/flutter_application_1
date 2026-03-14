import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_picker_helper.dart';

class PreRideScreen extends StatefulWidget {
  const PreRideScreen({Key? key}) : super(key: key);

  @override
  State<PreRideScreen> createState() => _PreRideScreenState();
}

class _PreRideScreenState extends State<PreRideScreen> {
  XFile? _truckExteriorPhoto;
  XFile? _odometerPhoto;
  XFile? _manifestPhoto;
  XFile? _fuelDetailsPhoto;

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
          SnackBar(content: Text('Photo uploaded: ${image.name}')),
        );
      }
    }
  }

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
