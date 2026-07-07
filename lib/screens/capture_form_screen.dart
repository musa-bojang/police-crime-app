import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/offence.dart';
import '../models/offence_image.dart';
import '../services/location_service.dart';
import '../services/offence_store.dart';
import '../services/photo_service.dart';

class CaptureFormScreen extends StatefulWidget {
  const CaptureFormScreen({super.key});

  @override
  State<CaptureFormScreen> createState() => _CaptureFormScreenState();
}

class _CaptureFormScreenState extends State<CaptureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _photoService = PhotoService();

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
  bool _saving = false;

  final List<CapturedPhoto> _photos = [];

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

  Future<void> _takePhoto() async {
    final photo = await _photoService.takePhoto();
    if (photo != null) {
      setState(() => _photos.add(photo));
    }
  }

  Future<void> _removePhoto(CapturedPhoto photo) async {
    setState(() => _photos.remove(photo));
    try {
      await File(photo.filePath).delete();
    } catch (_) {
      // Best-effort cleanup; ignore if the file is already gone.
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final position = await LocationService().getCurrentPosition();

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
      latitude: position?.latitude,
      longitude: position?.longitude,
    );

    // Turn the captured photos into image records linked to this offence.
    final images = _photos
        .map((ph) => OffenceImage.fromCapture(
              id: ph.id,
              offenceId: offence.id,
              filePath: ph.filePath,
              sha256Hash: ph.sha256Hash,
              fileSize: ph.fileSize,
              mimeType: ph.mimeType,
              latitude: position?.latitude,
              longitude: position?.longitude,
            ))
        .toList();

    await context.read<OffenceStore>().add(offence, images: images);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    final photoNote = images.isEmpty ? '' : ' with ${images.length} photo(s)';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Offence saved$photoNote')),
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
            const SizedBox(height: 20),

            // --- Evidence photos ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Evidence photos',
                    style: Theme.of(context).textTheme.titleMedium),
                OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take photo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_photos.isEmpty)
              const Text('No photos yet.',
                  style: TextStyle(color: Colors.grey))
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final photo = _photos[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(photo.filePath),
                              width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _removePhoto(photo),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save offence'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
