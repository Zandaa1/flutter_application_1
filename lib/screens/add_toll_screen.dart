import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/image_picker_helper.dart';
import '../services/mock_backend_service.dart';

class AddTollScreen extends StatefulWidget {
  const AddTollScreen({super.key});

  @override
  State<AddTollScreen> createState() => _AddTollScreenState();
}

class _AddTollScreenState extends State<AddTollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();
  XFile? _receiptPhoto;

  Future<void> _pickImage() async {
    final XFile? image = await ImagePickerHelper.showImageSourceDialog(context);
    if (image != null) {
      setState(() {
        _receiptPhoto = image;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Toll receipt uploaded: ${image.name}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submitToll() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_receiptPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload toll receipt photo')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    MockBackendService.addTollExpense(
      receiptFile: File(_receiptPhoto!.path),
      expresswayOrLocation: _locationController.text.trim(),
      amountPesos: amount,
    );

    // Process toll submission
    setState(() {
      _receiptPhoto = null;
      _amountController.clear();
      _locationController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toll expense submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Go back after successful submission
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Toll Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 16),
            // Toll Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Toll Amount (₱)',
                prefixIcon: Icon(Icons.attach_money_rounded),
                helperText: 'Amount paid for toll',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter toll amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Toll Location/Name
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.edit_road),
                helperText: 'e.g. NLEX, SLEX, Skyway',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter toll location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Tip: Add tolls after the stop/parking area for safety.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _submitToll,
              icon: const Icon(Icons.upload),
              label: const Text('Submit Toll Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}
