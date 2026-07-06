import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/offence.dart';
import '../services/offence_store.dart';

class CaptureFormScreen extends StatefulWidget {
  const CaptureFormScreen({super.key});

  @override
  State<CaptureFormScreen> createState() => _CaptureFormScreenState();
}

class _CaptureFormScreenState extends State<CaptureFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Fixed option lists. These strings are what get stored and later synced.
  static const _offenceTypes = [
    'speeding',
    'reckless_driving',
    'no_seatbelt',
    'no_license',
    'expired_documents',
    'illegal_parking',
    'using_phone',
    'other',
  ];
  static const _vehicleTypes = ['car', 'motorcycle', 'truck', 'bus', 'other'];
  static const _genders = ['male', 'female', 'unknown'];

  String? _offenceType;
  String? _vehicleType;
  String? _driverGender;
  bool _driverFled = false;

  final _plate = TextEditingController();
  final _color = TextEditingController();
  final _make = TextEditingController();
  final _driverName = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _plate.dispose();
    _color.dispose();
    _make.dispose();
    _driverName.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _nullIfBlank(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final offence = Offence.create(
      offenceType: _offenceType!,
      offenceDescription: _nullIfBlank(_description),
      vehiclePlate: _nullIfBlank(_plate),
      vehicleColor: _nullIfBlank(_color),
      vehicleMake: _nullIfBlank(_make),
      vehicleType: _vehicleType,
      driverGender: _driverGender,
      driverName: _nullIfBlank(_driverName),
      driverFled: _driverFled,
      locationDescription: _nullIfBlank(_location),
      // latitude/longitude come in the GPS step.
    );

    await context.read<OffenceStore>().add(offence);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offence saved to device')),
    );
  }

  String _label(String raw) =>
      raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Offence')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _offenceType,
              decoration: const InputDecoration(
                labelText: 'Offence type *',
                border: OutlineInputBorder(),
              ),
              items: _offenceTypes
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(_label(t))))
                  .toList(),
              onChanged: (v) => setState(() => _offenceType = v),
              validator: (v) => v == null ? 'Select an offence type' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Vehicle plate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _color,
              decoration: const InputDecoration(
                labelText: 'Vehicle colour',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: const InputDecoration(
                labelText: 'Vehicle type',
                border: OutlineInputBorder(),
              ),
              items: _vehicleTypes
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(_label(t))))
                  .toList(),
              onChanged: (v) => setState(() => _vehicleType = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _make,
              decoration: const InputDecoration(
                labelText: 'Vehicle make (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _driverGender,
              decoration: const InputDecoration(
                labelText: 'Driver gender',
                border: OutlineInputBorder(),
              ),
              items: _genders
                  .map((g) =>
                      DropdownMenuItem(value: g, child: Text(_label(g))))
                  .toList(),
              onChanged: (v) => setState(() => _driverGender = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _driverName,
              decoration: const InputDecoration(
                labelText: 'Driver name (if known)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Driver fled the scene'),
              value: _driverFled,
              onChanged: (v) => setState(() => _driverFled = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save offence'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
