import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_picker_helper.dart';

class FuelReceiptScreen extends StatefulWidget {
  const FuelReceiptScreen({Key? key}) : super(key: key);

  @override
  State<FuelReceiptScreen> createState() => _FuelReceiptScreenState();
}

class _FuelReceiptScreenState extends State<FuelReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalPesosController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _litersController = TextEditingController();
  XFile? _receiptPhoto;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Fuel Receipt'),
      ),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Receipt Photo Upload
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _receiptPhoto != null
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    _receiptPhoto != null ? Icons.check : Icons.receipt,
                    color: _receiptPhoto != null
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('Receipt Photo'),
                subtitle: Text(_receiptPhoto != null ? 'Photo uploaded' : 'Take photo of receipt'),
                trailing: ElevatedButton(
                  onPressed: _pickImage,
                  child: Text(_receiptPhoto != null ? 'Change' : 'Upload'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Total Amount
            TextFormField(
              controller: _totalPesosController,
              decoration: const InputDecoration(
                labelText: 'Total Amount (₱)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                helperText: 'Total cost in Pesos',
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
                helperText: 'Price per liter in Pesos',
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.opacity),
                helperText: 'Total liters purchased',
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
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate() && _receiptPhoto != null) {
                  // TODO: Submit to API
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fuel receipt submitted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } else if (_receiptPhoto == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please upload receipt photo'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Submit Receipt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
