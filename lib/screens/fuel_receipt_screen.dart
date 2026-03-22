import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/image_picker_helper.dart';
import '../services/fuel_receipt_history_service.dart';
import '../services/mock_backend_service.dart';

class FuelReceiptScreen extends StatefulWidget {
  const FuelReceiptScreen({super.key});

  @override
  State<FuelReceiptScreen> createState() => _FuelReceiptScreenState();
}

class _FuelReceiptScreenState extends State<FuelReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalPesosController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _litersController = TextEditingController();
  XFile? _receiptPhoto;
  String _tripId = 'unknown_trip';
  List<FuelReceiptRecord> _receiptHistory = <FuelReceiptRecord>[];
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _tripId = args;
    }

    _loadHistory();
    _isInitialized = true;
  }

  void _loadHistory() {
    setState(() {
      _receiptHistory = MockBackendService.getFuelReceiptsForTrip(_tripId);
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePickerHelper.showImageSourceDialog(context);
    if (image != null) {
      setState(() {
        _receiptPhoto = image;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt photo uploaded: ${image.name}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _totalPesosController.dispose();
    _pricePerLiterController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  void _calculateField() {
    // Auto-calculate liters if total and price are filled
    if (_totalPesosController.text.isNotEmpty &&
        _pricePerLiterController.text.isNotEmpty) {
      final total = double.tryParse(_totalPesosController.text);
      final pricePerLiter = double.tryParse(_pricePerLiterController.text);

      if (total != null && pricePerLiter != null && pricePerLiter > 0) {
        final liters = total / pricePerLiter;
        _litersController.text = liters.toStringAsFixed(2);
      }
    }
  }

  void _submitReceipt() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_receiptPhoto == null) {
      // TODO: In production, require a photo. For testing we allow submission without one.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note: No receipt photo attached (test mode)'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final total = double.parse(_totalPesosController.text);
    final pricePerLiter = double.parse(_pricePerLiterController.text);
    final liters = double.parse(_litersController.text);

    final photoFile = File(_receiptPhoto!.path);
    MockBackendService.addFuelReceipt(
      tripId: _tripId,
      photoFile: photoFile,
      totalPesos: total,
      pricePerLiter: pricePerLiter,
      liters: liters,
    );

    _loadHistory();

    setState(() {
      _receiptPhoto = null;
      _totalPesosController.clear();
      _pricePerLiterController.clear();
      _litersController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fuel receipt submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuel Receipt Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload receipt photo and enter fuel details',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trip ID: $_tripId',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Photo Upload
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _receiptPhoto != null
                          ? cs.tertiary
                          : cs.primaryContainer,
                      child: Icon(
                        _receiptPhoto != null ? Icons.check : Icons.receipt,
                        color: _receiptPhoto != null
                            ? cs.onTertiary
                            : cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receipt Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _receiptPhoto != null
                                ? 'Photo uploaded'
                                : 'Take photo of receipt',
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: _pickImage,
                      child: Text(_receiptPhoto != null ? 'Change' : 'Add'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Total Amount
            TextFormField(
              controller: _totalPesosController,
              decoration: const InputDecoration(
                labelText: 'Total Amount (₱)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) => _calculateField(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter total amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price Per Liter
            TextFormField(
              controller: _pricePerLiterController,
              decoration: const InputDecoration(
                labelText: 'Price Per Liter (₱)',
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) => _calculateField(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price per liter';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Liters
            TextFormField(
              controller: _litersController,
              decoration: const InputDecoration(
                labelText: 'Liters',
                prefixIcon: Icon(Icons.opacity),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter liters';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Tip: For your safety, only fill the details while parked.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _submitReceipt,
              icon: const Icon(Icons.check),
              label: const Text('Submit Receipt'),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuel Receipt History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Receipts uploaded in this trip: ${_receiptHistory.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    if (_receiptHistory.isEmpty)
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No receipts uploaded for this trip yet. Don\'t forget to submit your fuel receipts to keep track of your expenses! ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      )
                    else
                      ..._receiptHistory.map((record) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.receipt_long),
                            ),
                            title: Text(
                              'P${record.totalPesos.toStringAsFixed(2)}',
                            ),
                            subtitle: Text(
                              '${record.photoName}\n'
                              '${record.liters.toStringAsFixed(2)} L @ P${record.pricePerLiter.toStringAsFixed(2)} /L',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              '${record.uploadedAt.month.toString().padLeft(2, '0')}/'
                              '${record.uploadedAt.day.toString().padLeft(2, '0')} '
                              '${record.uploadedAt.hour.toString().padLeft(2, '0')}:'
                              '${record.uploadedAt.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
